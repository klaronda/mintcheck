import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router';
import { Helmet } from 'react-helmet-async';
import { Plus, Edit, Trash2, Eye, EyeOff, LogOut, ExternalLink, Upload } from 'lucide-react';
import { useAdmin, Article, AUTH_KEY } from '@/app/contexts/AdminContext';
import { supabase } from '@/lib/supabase';
import RichTextEditor from '@/app/components/RichTextEditor';

export default function AdminDashboard() {
  const navigate = useNavigate();
  const { articles, addArticle, updateArticle, deleteArticle } = useAdmin();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | 'support' | 'blog'>('all');

  const [formData, setFormData] = useState({
    type: 'support' as 'support' | 'blog',
    title: '',
    slug: '',
    cardDescription: '',
    summary: '',
    heroImage: '',
    body: '',
    category: 'Using the App' as 'Device Help' | 'Using the App' | 'Vehicle Support' | undefined,
    published: true,
  });

  useEffect(() => {
    const auth = localStorage.getItem(AUTH_KEY);
    if (auth !== 'true') {
      navigate('/admin/login');
    } else {
      setIsAuthenticated(true);
    }
  }, [navigate]);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    localStorage.removeItem(AUTH_KEY);
    navigate('/admin/login');
  };

  const resetForm = () => {
    setFormData({
      type: 'support',
      title: '',
      slug: '',
      cardDescription: '',
      summary: '',
      heroImage: '',
      body: '',
      category: 'Using the App',
      published: true,
    });
    setEditingId(null);
    setShowForm(false);
  };

  const handleEdit = (article: Article) => {
    setFormData({
      type: article.type,
      title: article.title,
      slug: article.slug,
      cardDescription: article.cardDescription,
      summary: article.summary,
      heroImage: article.heroImage,
      body: article.body,
      category: article.category,
      published: article.published,
    });
    setEditingId(article.id);
    setShowForm(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (editingId) {
      updateArticle(editingId, formData);
    } else {
      addArticle(formData);
    }
    
    resetForm();
  };

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this article?')) {
      deleteArticle(id);
    }
  };

  const togglePublished = (id: string, published: boolean) => {
    updateArticle(id, { published: !published });
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setFormData({ ...formData, heroImage: reader.result as string });
      };
      reader.readAsDataURL(file);
    }
  };

  const filteredArticles = articles.filter(article => {
    if (filter === 'all') return true;
    return article.type === filter;
  });

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Helmet>
        <title>Admin Dashboard | MintCheck</title>
        <meta name="robots" content="noindex, nofollow" />
      </Helmet>

      {/* Header */}
      <div className="bg-white border-b border-border">
        <div className="max-w-7xl mx-auto px-6 py-4 flex justify-between items-center">
          <h1 className="text-2xl" style={{ fontWeight: 600 }}>
            MintCheck Admin
          </h1>
          <div className="flex items-center gap-4">
            <a
              href="/admin/feedback"
              className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
            >
              Feedback
            </a>
            <a
              href="/"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
            >
              <ExternalLink className="w-4 h-4" />
              View Site
            </a>
            <button
              onClick={handleLogout}
              className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
            >
              <LogOut className="w-4 h-4" />
              Logout
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* Add New Button */}
        {!showForm && (
          <div className="mb-8">
            <button
              onClick={() => setShowForm(true)}
              className="flex items-center gap-2 bg-[#3EB489] text-white px-6 py-3 rounded-lg hover:bg-[#359e7a] transition-colors"
              style={{ fontWeight: 600 }}
            >
              <Plus className="w-5 h-5" />
              New Article
            </button>
          </div>
        )}

        {/* Form */}
        {showForm && (
          <div className="bg-white rounded-lg border border-border p-6 mb-8">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-xl" style={{ fontWeight: 600 }}>
                {editingId ? 'Edit Article' : 'New Article'}
              </h2>
              <button
                onClick={resetForm}
                className="text-muted-foreground hover:text-foreground"
              >
                Cancel
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-6 max-h-[70vh] overflow-y-auto pr-4">
              {/* Basic Info */}
              <div className="space-y-4 pb-6 border-b border-border">
                <h3 style={{ fontWeight: 600 }}>Basic Information</h3>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm mb-2" style={{ fontWeight: 600 }}>
                      Type *
                    </label>
                    <select
                      value={formData.type}
                      onChange={(e) => setFormData({ ...formData, type: e.target.value as 'support' | 'blog', category: e.target.value === 'blog' ? undefined : 'Using the App' })}
                      className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3EB489]"
                      required
                    >
                      <option value="support">Support Article</option>
                      <option value="blog">Blog Post</option>
                    </select>
                  </div>

                  {formData.type === 'support' && (
                    <div>
                      <label className="block text-sm mb-2" style={{ fontWeight: 600 }}>
                        Category *
                      </label>
                      <select
                        value={formData.category}
                        onChange={(e) => setFormData({ ...formData, category: e.target.value as any })}
                        className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3EB489]"
                        required
                      >
                        <option value="Device Help">Device Help</option>
                        <option value="Using the App">Using the App</option>
                        <option value="Vehicle Support">Vehicle Support</option>
                      </select>
                    </div>
                  )}
                </div>

                <div>
                  <label className="block text-sm mb-2" style={{ fontWeight: 600 }}>
                    Title (H1) *
                  </label>
                  <input
                    type="text"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value, slug: e.target.value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') })}
                    className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3EB489]"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm mb-2" style={{ fontWeight: 600 }}>
                    Slug (URL) *
                  </label>
                  <input
                    type="text"
                    value={formData.slug}
                    onChange={(e) => setFormData({ ...formData, slug: e.target.value })}
                    className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3EB489]"
                    required
                  />
                  <p className="text-sm text-muted-foreground mt-1">
                    URL: /{formData.type}/{formData.slug}
                  </p>
                </div>

                <div>
                  <label className="block text-sm mb-2" style={{ fontWeight: 600 }}>
                    Card Description *
                  </label>
                  <input
                    type="text"
                    value={formData.cardDescription}
                    onChange={(e) => setFormData({ ...formData, cardDescription: e.target.value })}
                    className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3EB489]"
                    required
                    placeholder="Short description for cards and previews"
                  />
                </div>

                <div>
                  <label className="block text-sm mb-2" style={{ fontWeight: 600 }}>
                    Page Summary *
                  </label>
                  <textarea
                    value={formData.summary}
                    onChange={(e) => setFormData({ ...formData, summary: e.target.value })}
                    className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3EB489]"
                    rows={3}
                    required
                    placeholder="Summary shown below the title"
                  />
                </div>
              </div>

              {/* Hero Image */}
              <div className="space-y-4 pb-6 border-b border-border">
                <h3 style={{ fontWeight: 600 }}>Hero Image</h3>
                
                <div>
                  <label className="block text-sm mb-2" style={{ fontWeight: 600 }}>
                    Image URL *
                  </label>
                  <input
                    type="url"
                    value={formData.heroImage}
                    onChange={(e) => setFormData({ ...formData, heroImage: e.target.value })}
                    className="w-full px-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#3EB489]"
                    required
                    placeholder="https://images.unsplash.com/..."
                  />
                </div>

                <div>
                  <label className="block text-sm mb-2" style={{ fontWeight: 600 }}>
                    Or Upload Image
                  </label>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleImageUpload}
                    className="hidden"
                    id="imageUpload"
                  />
                  <label
                    htmlFor="imageUpload"
                    className="inline-flex items-center gap-2 bg-[#3EB489] text-white px-4 py-2 rounded-lg hover:bg-[#359e7a] transition-colors cursor-pointer"
                  >
                    <Upload className="w-4 h-4" />
                    Upload Image
                  </label>
                </div>

                {formData.heroImage && (
                  <img
                    src={formData.heroImage}
                    alt="Preview"
                    className="w-full h-48 object-cover rounded-lg"
                  />
                )}
              </div>

              {/* Body */}
              <div className="space-y-4">
                <h3 style={{ fontWeight: 600 }}>Article Body *</h3>
                
                <RichTextEditor
                  value={formData.body}
                  onChange={(value) => setFormData({ ...formData, body: value })}
                  placeholder="Write your article content here..."
                />
              </div>

              {/* Published Toggle */}
              <div className="flex items-center gap-3 pt-6 border-t border-border">
                <input
                  type="checkbox"
                  id="published"
                  checked={formData.published}
                  onChange={(e) => setFormData({ ...formData, published: e.target.checked })}
                  className="w-4 h-4"
                />
                <label htmlFor="published" style={{ fontWeight: 600 }}>
                  Publish immediately
                </label>
              </div>

              {/* Submit */}
              <div className="flex gap-4">
                <button
                  type="submit"
                  className="bg-[#3EB489] text-white px-6 py-3 rounded-lg hover:bg-[#359e7a] transition-colors"
                  style={{ fontWeight: 600 }}
                >
                  {editingId ? 'Update Article' : 'Create Article'}
                </button>
                <button
                  type="button"
                  onClick={resetForm}
                  className="border border-border px-6 py-3 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Filter */}
        <div className="flex gap-2 mb-6">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-lg transition-colors ${filter === 'all' ? 'bg-[#3EB489] text-white' : 'border border-border hover:bg-gray-50'}`}
          >
            All ({articles.length})
          </button>
          <button
            onClick={() => setFilter('support')}
            className={`px-4 py-2 rounded-lg transition-colors ${filter === 'support' ? 'bg-[#3EB489] text-white' : 'border border-border hover:bg-gray-50'}`}
          >
            Support ({articles.filter(a => a.type === 'support').length})
          </button>
          <button
            onClick={() => setFilter('blog')}
            className={`px-4 py-2 rounded-lg transition-colors ${filter === 'blog' ? 'bg-[#3EB489] text-white' : 'border border-border hover:bg-gray-50'}`}
          >
            Blog ({articles.filter(a => a.type === 'blog').length})
          </button>
        </div>

        {/* Articles List */}
        <div className="space-y-4">
          {filteredArticles.map(article => (
            <div key={article.id} className="bg-white rounded-lg border border-border p-6 flex gap-6">
              <img
                src={article.heroImage}
                alt={article.title}
                className="w-32 h-32 object-cover rounded-lg flex-shrink-0"
              />
              
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-xs px-2 py-1 bg-gray-100 rounded">
                        {article.type}
                      </span>
                      {article.category && (
                        <span className="text-xs px-2 py-1 bg-[#3EB489]/10 text-[#3EB489] rounded">
                          {article.category}
                        </span>
                      )}
                      {!article.published && (
                        <span className="text-xs px-2 py-1 bg-red-100 text-red-700 rounded">
                          Draft
                        </span>
                      )}
                    </div>
                    <h3 className="text-lg mb-1" style={{ fontWeight: 600 }}>
                      {article.title}
                    </h3>
                    <p className="text-sm text-muted-foreground mb-2">
                      /{article.type}/{article.slug}
                    </p>
                    <p className="text-sm text-muted-foreground">
                      {article.cardDescription}
                    </p>
                  </div>

                  <div className="flex gap-2 flex-shrink-0">
                    <button
                      onClick={() => togglePublished(article.id, article.published)}
                      className="p-2 hover:bg-gray-100 rounded transition-colors"
                      title={article.published ? 'Unpublish' : 'Publish'}
                    >
                      {article.published ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                    </button>
                    <button
                      onClick={() => handleEdit(article)}
                      className="p-2 hover:bg-gray-100 rounded transition-colors"
                      title="Edit"
                    >
                      <Edit className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDelete(article.id)}
                      className="p-2 hover:bg-red-50 text-red-600 rounded transition-colors"
                      title="Delete"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}

          {filteredArticles.length === 0 && (
            <div className="text-center py-12 text-muted-foreground">
              No articles yet. Create your first one!
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
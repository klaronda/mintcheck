import { useState } from "react";
import { Button } from "@/app/components/ui/button";
import { Input } from "@/app/components/ui/input";
import { Label } from "@/app/components/ui/label";
import { ArrowLeft } from "lucide-react";

interface SignInScreenProps {
  onBack: () => void;
  onSignIn: (data: { email: string; firstName: string; lastName: string; birthdate: string }) => void;
  onCreateAccount: () => void;
  startWithSignUp?: boolean;
}

export function SignInScreen({ onBack, onSignIn, onCreateAccount, startWithSignUp = false }: SignInScreenProps) {
  const [isCreatingAccount, setIsCreatingAccount] = useState(startWithSignUp);
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    firstName: "",
    lastName: "",
    birthdate: "",
  });
  
  const [showAgeDisclaimer, setShowAgeDisclaimer] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (isCreatingAccount) {
      // Check age
      if (formData.birthdate) {
        const birthYear = new Date(formData.birthdate).getFullYear();
        const currentYear = new Date().getFullYear();
        const age = currentYear - birthYear;
        
        if (age < 16) {
          setShowAgeDisclaimer(true);
          return;
        }
      }
      
      onSignIn({
        email: formData.email,
        firstName: formData.firstName,
        lastName: formData.lastName,
        birthdate: formData.birthdate,
      });
    } else {
      // For demo, just sign in
      onSignIn({
        email: formData.email,
        firstName: "Demo",
        lastName: "User",
        birthdate: "",
      });
    }
  };

  return (
    <div className="min-h-screen bg-[#F8F8F7] flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-[#E5E5E5]">
        <div className="max-w-md mx-auto px-6 py-4 flex items-center">
          <button
            onClick={onBack}
            className="p-2 -ml-2 text-[#666666] hover:text-[#1A1A1A] transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <h1 className="flex-1 text-center pr-8 text-[#1A1A1A]" style={{ fontSize: '17px', fontWeight: 600 }}>
            {isCreatingAccount ? "Create Account" : "Sign In"}
          </h1>
        </div>
      </div>

      {/* Form */}
      <div className="flex-1 px-6 pt-8 max-w-md mx-auto w-full">
        <form onSubmit={handleSubmit} className="space-y-5">
          {isCreatingAccount && (
            <>
              <div className="space-y-1.5">
                <Label htmlFor="firstName" className="text-[#1A1A1A]">First Name</Label>
                <Input
                  id="firstName"
                  type="text"
                  placeholder="John"
                  value={formData.firstName}
                  onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                  className="h-11 bg-white placeholder:text-[#999999] border-[#E5E5E5] text-[#1A1A1A] rounded"
                  required
                />
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="lastName" className="text-[#1A1A1A]">Last Name</Label>
                <Input
                  id="lastName"
                  type="text"
                  placeholder="Smith"
                  value={formData.lastName}
                  onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                  className="h-11 bg-white placeholder:text-[#999999] border-[#E5E5E5] text-[#1A1A1A] rounded"
                  required
                />
              </div>
            </>
          )}

          <div className="space-y-1.5">
            <Label htmlFor="email" className="text-[#1A1A1A]">Email</Label>
            <Input
              id="email"
              type="email"
              placeholder="john@example.com"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              className="h-11 bg-white placeholder:text-[#999999] border-[#E5E5E5] text-[#1A1A1A] rounded"
              required
            />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="password" className="text-[#1A1A1A]">Password</Label>
            <Input
              id="password"
              type="password"
              placeholder="••••••••"
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
              className="h-11 bg-white placeholder:text-[#999999] border-[#E5E5E5] text-[#1A1A1A] rounded"
              required
            />
          </div>

          {isCreatingAccount && (
            <div className="space-y-1.5">
              <Label htmlFor="birthdate" className="text-[#1A1A1A]">Birthdate</Label>
              <Input
                id="birthdate"
                type="date"
                placeholder="MM/DD/YYYY"
                value={formData.birthdate}
                onChange={(e) => setFormData({ ...formData, birthdate: e.target.value })}
                className="h-11 bg-white placeholder:text-[#999999] border-[#E5E5E5] text-[#1A1A1A] rounded"
              />
              {showAgeDisclaimer && (
                <p className="text-[#DC3545] leading-relaxed pt-1" style={{ fontSize: '14px' }}>
                  We recommend having an adult assist with your vehicle inspection. You can continue, but please involve a parent or guardian in your decision.
                </p>
              )}
            </div>
          )}

          <div className="pt-2">
            <Button
              type="submit"
              className="w-full h-12 bg-[#3EB489] hover:bg-[#2D9970] text-white rounded"
              style={{ fontWeight: 600 }}
            >
              {isCreatingAccount ? "Create Account" : "Sign In"}
            </Button>
          </div>

          <div className="text-center pt-2">
            <button
              type="button"
              onClick={() => setIsCreatingAccount(!isCreatingAccount)}
              className="text-[#666666] hover:text-[#1A1A1A] transition-colors"
              style={{ fontSize: '15px', fontWeight: 600 }}
            >
              {isCreatingAccount
                ? "Already have an account? Sign in"
                : "Don't have an account? Create one"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
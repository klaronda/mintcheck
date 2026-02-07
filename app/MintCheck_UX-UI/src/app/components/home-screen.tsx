import { Button } from "@/app/components/ui/button";
import logoImage from "figma:asset/f82fe1ed3683a8a691868d9d94c344bcff290175.png";

interface HomeScreenProps {
  onStartCheck: () => void;
  onSignIn: () => void;
}

export function HomeScreen({ onStartCheck, onSignIn }: HomeScreenProps) {
  return (
    <div className="relative min-h-screen w-full flex flex-col bg-[#1A1A1A]">
      {/* Hero Image */}
      <div className="relative w-full h-screen">
        <img
          src="https://images.unsplash.com/photo-1609465397944-be1ce3ebda61?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXIlMjBkYXNoYm9hcmQlMjBpbnRlcmlvcnxlbnwxfHx8fDE3Njg4MDg2NDN8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
          alt="Car dashboard"
          className="w-full h-full object-cover"
        />
        
        {/* Gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-b from-black/40 via-black/20 to-black/70" />
        
        {/* Logo */}
        <div className="absolute top-8 left-1/2 -translate-x-1/2">
          <div className="flex items-center gap-2.5">
            <img 
              src={logoImage} 
              alt="MintCheck logo" 
              className="h-9 w-auto object-contain"
            />
            <span className="text-white" style={{ fontSize: '20px', fontWeight: 600, letterSpacing: '-0.01em' }}>
              MintCheck
            </span>
          </div>
        </div>
        
        {/* Main Content */}
        <div className="absolute inset-0 flex flex-col items-center justify-end px-6 pb-12">
          <div className="w-full max-w-md space-y-3">
            {/* Headline */}
            <div className="mb-8 text-center">
              <h1 className="text-white mb-2" style={{ fontSize: '28px', fontWeight: 600, lineHeight: '1.2', letterSpacing: '-0.01em' }}>
                Know Before You Buy
              </h1>
              <p className="text-white/75" style={{ fontSize: '16px', lineHeight: '1.5' }}>
                Check used car vitals and real value in minutes
              </p>
            </div>
            
            {/* Primary CTA */}
            <Button
              onClick={onStartCheck}
              className="w-full h-12 bg-[#3EB489] hover:bg-[#2D9970] text-white rounded"
              style={{ fontSize: '16px', fontWeight: 600 }}
            >
              Start a Vehicle Check
            </Button>
            
            {/* Secondary CTA */}
            <Button
              onClick={onSignIn}
              variant="outline"
              className="w-full h-12 bg-white/95 hover:bg-white text-[#1A1A1A] border-0 rounded"
              style={{ fontSize: '16px', fontWeight: 600 }}
            >
              Create Account
            </Button>
            
            {/* Testimonial */}
            <div className="pt-4">
              <p className="text-white/60 text-center" style={{ fontSize: '14px' }}>
                "MintCheck was like bringing my own mechanic to buy a used car"
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
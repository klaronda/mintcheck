import { useState } from "react";
import { Button } from "@/app/components/ui/button";
import { CheckCircle2, Wifi, FileText, ArrowLeft, AlertCircle, XCircle, Info } from "lucide-react";

interface OnboardingScreenProps {
  onComplete: () => void;
  onBack: () => void;
}

export function OnboardingScreen({ onComplete, onBack }: OnboardingScreenProps) {
  const [currentStep, setCurrentStep] = useState(0);

  const steps = [
    {
      icon: CheckCircle2,
      title: "Buy a more reliable used car.",
      description:
        "MintCheck does a quick check on the car you’re looking at, so you know the health before you buy.",
    },
    {
      icon: Wifi,
      title: "Plug in and press start.",
      description:
        "MintCheck works with a small Wi-Fi or Bluetooth scanner that plugs into the car. If you don’t have one yet, we’ll help you find one for ~$13.",
    },
    {
      icon: FileText,
      title: "Get trusted results.",
      description:
        "In just a few minutes, MintCheck gives you the recommendation you need to buy—or walk away—with full confidence.",
      showBadges: true,
    },
  ];

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      onComplete();
    }
  };

  const handleBack = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    } else {
      onBack();
    }
  };

  const handleSkip = () => {
    onComplete();
  };

  const step = steps[currentStep];
  const Icon = step.icon;

  return (
    <div className="min-h-screen bg-[#F8F8F7] flex flex-col">
      {/* Header with progress */}
      <div className="bg-white border-b border-[#E5E5E5]">
        <div className="max-w-md mx-auto px-6 py-4">
          <div className="flex items-center gap-4">
            <button
              onClick={handleBack}
              className="p-2 -ml-2 text-[#666666] hover:text-[#1A1A1A] transition-colors"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
            
            {/* Progress bar */}
            <div className="flex-1 h-1 bg-[#E5E5E5] rounded-full overflow-hidden">
              <div 
                className="h-full bg-[#3EB489] transition-all duration-300 ease-in-out"
                style={{ width: `${((currentStep + 1) / steps.length) * 100}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto pb-32">
        <div className="flex flex-col items-center justify-center px-6 max-w-md mx-auto min-h-full pt-12">
          {/* Icon - minimal */}
          <div className="w-16 h-16 mb-8">
            <Icon className="w-16 h-16 text-[#1A1A1A]" strokeWidth={1.5} />
          </div>

          {/* Title */}
          <h2 className="text-center mb-3 text-[#1A1A1A]" style={{ fontSize: '24px', fontWeight: 600, lineHeight: '1.3', letterSpacing: '-0.01em' }}>
            {step.title}
          </h2>

          {/* Description */}
          <p className="text-[#666666] text-center leading-relaxed mb-10" style={{ fontSize: '16px' }}>
            {step.description}
          </p>

          {/* Recommendation Badges (on last screen) */}
          {step.showBadges && (
            <div className="w-full space-y-2.5 mb-10">
              <div className="flex items-center gap-3 bg-[#FCFCFB] border border-[#E5E5E5] rounded p-4">
                <div className="w-10 h-10 rounded bg-[#3EB489] flex items-center justify-center flex-shrink-0">
                  <CheckCircle2 className="w-5 h-5 text-white" strokeWidth={2} />
                </div>
                <span className="text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  Safe to Buy
                </span>
              </div>
              
              <div className="flex items-center gap-3 bg-[#FCFCFB] border border-[#E5E5E5] rounded p-4">
                <div className="w-10 h-10 rounded bg-[#F59E0B] flex items-center justify-center flex-shrink-0">
                  <AlertCircle className="w-5 h-5 text-white" strokeWidth={2} />
                </div>
                <span className="text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  Proceed with Caution
                </span>
              </div>
              
              <div className="flex items-center gap-3 bg-[#FCFCFB] border border-[#E5E5E5] rounded p-4">
                <div className="w-10 h-10 rounded bg-[#DC3545] flex items-center justify-center flex-shrink-0">
                  <XCircle className="w-5 h-5 text-white" strokeWidth={2} />
                </div>
                <span className="text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  Not Recommended
                </span>
              </div>
            </div>
          )}

          {/* Important Note on Last Step */}
          {currentStep === steps.length - 1 && (
            <div className="w-full flex items-start gap-2 mb-10">
              <Info className="w-4 h-4 text-[#666666] flex-shrink-0 mt-0.5" strokeWidth={2} />
              <p className="text-[#666666] leading-relaxed" style={{ fontSize: '13px' }}>
                MintCheck helps you decide. It doesn't replace a professional mechanic inspection.
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Sticky Bottom Buttons */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-[#E5E5E5] px-6 py-4">
        <div className="max-w-md mx-auto space-y-2.5">
          <Button
            onClick={handleNext}
            className="w-full h-12 bg-[#3EB489] hover:bg-[#2D9970] text-white rounded"
            style={{ fontWeight: 600 }}
          >
            {currentStep === steps.length - 1 ? "Get Started" : "Next"}
          </Button>

          {currentStep < steps.length - 1 && (
            <Button
              onClick={handleSkip}
              variant="ghost"
              className="w-full h-12 text-[#666666] hover:text-[#1A1A1A] hover:bg-transparent"
              style={{ fontWeight: 600 }}
            >
              Skip
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}
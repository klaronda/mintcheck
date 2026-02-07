import { useEffect, useState } from "react";
import { CheckCircle2, Wifi } from "lucide-react";

interface DisconnectReconnectScreenProps {
  onComplete: () => void;
}

export function DisconnectReconnectScreen({ onComplete }: DisconnectReconnectScreenProps) {
  const [currentStep, setCurrentStep] = useState(0);

  const steps = [
    { icon: CheckCircle2, text: "Scan complete" },
    { icon: null, text: "Disconnecting from scanner..." },
    { icon: Wifi, text: "Reconnecting to internet..." },
    { icon: null, text: "Reviewing results..." },
  ];

  useEffect(() => {
    // Progress through steps
    const interval = setInterval(() => {
      setCurrentStep((prev) => {
        if (prev < steps.length - 1) {
          return prev + 1;
        }
        return prev;
      });
    }, 1500);

    // Complete after all steps
    const timeout = setTimeout(() => {
      clearInterval(interval);
      onComplete();
    }, 6500);

    return () => {
      clearInterval(interval);
      clearTimeout(timeout);
    };
  }, [onComplete]);

  const step = steps[currentStep];
  const Icon = step.icon;

  return (
    <div className="min-h-screen bg-[#F4F5F4] flex flex-col items-center justify-center px-6">
      <div className="max-w-md w-full text-center">
        {/* Icon or loader */}
        <div className="mb-6 flex justify-center">
          {Icon ? (
            <div className="w-16 h-16 rounded-full bg-[#E6F4EE] flex items-center justify-center">
              <Icon className="w-8 h-8 text-[#3EB489]" />
            </div>
          ) : (
            <div className="w-16 h-16 rounded-full border-4 border-[#E6F4EE] border-t-[#3EB489] animate-spin" />
          )}
        </div>

        {/* Status text */}
        <p className="text-[#2E2E2E] leading-relaxed" style={{ fontSize: '17px', fontWeight: 500 }}>
          {step.text}
        </p>
      </div>
    </div>
  );
}

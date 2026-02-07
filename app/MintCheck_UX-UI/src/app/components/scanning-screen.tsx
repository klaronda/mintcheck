import { useEffect, useState } from "react";
import { Gauge, Zap, Droplet, Wind, Thermometer, Activity, FileCheck } from "lucide-react";

interface ScanningScreenProps {
  onComplete: () => void;
}

export function ScanningScreen({ onComplete }: ScanningScreenProps) {
  const [currentStatus, setCurrentStatus] = useState(0);

  const statuses = [
    { text: "Connecting to vehicle...", icon: Activity },
    { text: "Reading vehicle data...", icon: FileCheck },
    { text: "Checking engine health...", icon: Gauge },
    { text: "Analyzing fuel system...", icon: Droplet },
    { text: "Checking emissions...", icon: Wind },
    { text: "Reviewing temperature controls...", icon: Thermometer },
    { text: "Finalizing scan...", icon: Zap },
  ];

  useEffect(() => {
    // Simulate scanning progress
    const interval = setInterval(() => {
      setCurrentStatus((prev) => {
        if (prev < statuses.length - 1) {
          return prev + 1;
        }
        return prev;
      });
    }, 2500);

    // Complete after ~20 seconds
    const timeout = setTimeout(() => {
      clearInterval(interval);
      onComplete();
    }, 18000);

    return () => {
      clearInterval(interval);
      clearTimeout(timeout);
    };
  }, [onComplete]);

  const currentIcon = statuses[currentStatus].icon;
  const CurrentIcon = currentIcon;

  return (
    <div className="min-h-screen bg-[#F8F8F7] flex flex-col items-center justify-center px-6">
      <div className="max-w-md w-full text-center">
        {/* Animated loader with icon */}
        <div className="mb-8 flex justify-center">
          <div className="relative">
            {/* Icon in center */}
            <div className="w-20 h-20 rounded bg-white border border-[#E5E5E5] flex items-center justify-center relative z-10">
              <CurrentIcon className="w-10 h-10 text-[#1A1A1A]" strokeWidth={1.5} />
            </div>
            {/* Spinning border */}
            <svg
              className="absolute inset-0 w-20 h-20 -rotate-90"
              viewBox="0 0 100 100"
            >
              <circle
                cx="50"
                cy="50"
                r="46"
                fill="none"
                stroke="#E5E5E5"
                strokeWidth="3"
              />
              <circle
                cx="50"
                cy="50"
                r="46"
                fill="none"
                stroke="#3EB489"
                strokeWidth="3"
                strokeDasharray="289.027"
                strokeDashoffset="0"
                strokeLinecap="round"
                className="animate-spin origin-center"
                style={{
                  animationDuration: "2s",
                  strokeDashoffset: `${289.027 * 0.25}`,
                }}
              />
            </svg>
          </div>
        </div>

        {/* Status text */}
        <div className="min-h-[60px]">
          <p className="text-[#1A1A1A] mb-2" style={{ fontSize: '17px', fontWeight: 600 }}>
            Scanning Vehicle
          </p>
          <p className="text-[#666666] leading-relaxed" style={{ fontSize: '15px' }}>
            {statuses[currentStatus].text}
          </p>
        </div>

        {/* Progress indicator */}
        <div className="mt-8">
          <div className="w-full h-1 bg-[#E5E5E5] rounded-full overflow-hidden">
            <div
              className="h-full bg-[#3EB489] transition-all duration-500 ease-out"
              style={{ width: `${((currentStatus + 1) / statuses.length) * 100}%` }}
            />
          </div>
          <p className="text-[#666666] mt-3" style={{ fontSize: '13px' }}>
            This usually takes 15-30 seconds
          </p>
        </div>

        {/* Reassurance message */}
        <div className="mt-12 bg-[#FCFCFB] border border-[#E5E5E5] rounded p-4">
          <p className="text-[#666666] leading-relaxed" style={{ fontSize: '14px' }}>
            Keep your phone nearby. The vehicle’s ignition should stay on during the scan.
          </p>
        </div>
      </div>
    </div>
  );
}
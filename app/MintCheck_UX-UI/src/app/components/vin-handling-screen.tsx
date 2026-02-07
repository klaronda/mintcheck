import { useState } from "react";
import { Button } from "@/app/components/ui/button";
import { Input } from "@/app/components/ui/input";
import { Label } from "@/app/components/ui/label";
import { Camera, AlertCircle } from "lucide-react";

interface VINHandlingScreenProps {
  onNext: (vin: string | null) => void;
  detectedVIN: string | null;
  vehicleInfo: { make: string; model: string; year: string };
}

export function VINHandlingScreen({ onNext, detectedVIN, vehicleInfo }: VINHandlingScreenProps) {
  const [vin, setVin] = useState(detectedVIN || "");
  const [showSkipWarning, setShowSkipWarning] = useState(false);

  const handleContinue = () => {
    if (vin.trim()) {
      onNext(vin.trim());
    } else {
      setShowSkipWarning(true);
    }
  };

  const handleSkip = () => {
    onNext(null);
  };

  return (
    <div className="min-h-screen bg-[#F8F8F7] flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-[#E5E5E5]">
        <div className="max-w-md mx-auto px-6 py-4">
          <h1 className="text-center text-[#1A1A1A]" style={{ fontSize: '17px', fontWeight: 600 }}>
            Vehicle Identification
          </h1>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 px-6 pt-8 max-w-md mx-auto w-full">
        {detectedVIN ? (
          <div className="bg-white border border-[#E5E5E5] rounded p-4 mb-6">
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded bg-[#3EB489] flex items-center justify-center flex-shrink-0">
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="white"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  className="w-5 h-5"
                >
                  <path d="M9 11l3 3L22 4" />
                  <path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11" />
                </svg>
              </div>
              <div>
                <p className="mb-1 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  VIN Detected
                </p>
                <p className="text-[#666666] leading-relaxed" style={{ fontSize: '14px' }}>
                  We found the vehicle identification number. You can confirm or edit it below.
                </p>
              </div>
            </div>
          </div>
        ) : (
          <div className="mb-6">
            <p className="text-[#666666] leading-relaxed" style={{ fontSize: '15px' }}>
              We couldn't detect the VIN automatically. You can enter it manually to help us validate the scan results.
            </p>
          </div>
        )}

        {/* VIN Info */}
        <div className="bg-white border border-[#E5E5E5] rounded p-4 mb-6">
          <p className="mb-2 text-[#1A1A1A]" style={{ fontSize: '14px', fontWeight: 600 }}>
            Where to find the VIN:
          </p>
          <ul className="text-[#666666] space-y-1" style={{ fontSize: '14px' }}>
            <li>• Driver's side dashboard (visible through windshield)</li>
            <li>• Driver's side door jamb sticker</li>
            <li>• Vehicle registration or insurance card</li>
          </ul>
        </div>

        {/* VIN Input */}
        <div className="space-y-1.5 mb-6">
          <Label htmlFor="vin" className="text-[#1A1A1A]">Vehicle Identification Number (VIN)</Label>
          <Input
            id="vin"
            type="text"
            placeholder="1HGBH41JXMN109186"
            value={vin}
            onChange={(e) => {
              setVin(e.target.value.toUpperCase());
              setShowSkipWarning(false);
            }}
            className="h-11 bg-white placeholder:text-[#999999] border-[#E5E5E5] rounded"
            maxLength={17}
          />
          <p className="text-[#666666] pt-1" style={{ fontSize: '14px' }}>
            Expected vehicle: {vehicleInfo.make} {vehicleInfo.model}
            {vehicleInfo.year && ` (${vehicleInfo.year})`}
          </p>
        </div>

        {/* Skip Warning */}
        {showSkipWarning && (
          <div className="bg-white border-2 border-[#F59E0B] rounded p-4 mb-6">
            <div className="flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-[#F59E0B] flex-shrink-0 mt-0.5" strokeWidth={2} />
              <div>
                <p className="mb-1 text-[#1A1A1A]" style={{ fontSize: '14px', fontWeight: 600 }}>
                  Lower Confidence Results
                </p>
                <p className="text-[#666666] leading-relaxed" style={{ fontSize: '14px' }}>
                  Without the VIN, we can't fully validate the vehicle information. Results will be marked with
                  lower confidence.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Buttons */}
        <div className="space-y-2.5">
          <Button
            onClick={handleContinue}
            className="w-full h-12 bg-[#3EB489] hover:bg-[#2D9970] text-white rounded"
            style={{ fontWeight: 600 }}
          >
            Continue
          </Button>

          {!showSkipWarning ? (
            <Button onClick={() => setShowSkipWarning(true)} variant="ghost" className="w-full h-12 text-[#666666] hover:text-[#1A1A1A] hover:bg-transparent" style={{ fontWeight: 600 }}>
              Skip VIN Entry
            </Button>
          ) : (
            <Button onClick={handleSkip} variant="ghost" className="w-full h-12 text-[#666666] hover:text-[#1A1A1A] hover:bg-transparent" style={{ fontWeight: 600 }}>
              Continue Without VIN
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}
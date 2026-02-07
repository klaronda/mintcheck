import { useState } from "react";
import { Button } from "@/app/components/ui/button";
import { 
  Droplet, 
  AlertTriangle, 
  Wind, 
  Droplets, 
  Disc, 
  Thermometer, 
  Battery, 
  Shield, 
  MoreHorizontal 
} from "lucide-react";

interface QuickHumanCheckScreenProps {
  onComplete: (data: {
    interiorCondition: string;
    tireCondition: string;
    dashboardLights: boolean;
    warningLightTypes?: string[];
    engineSounds: boolean;
  }) => void;
}

export function QuickHumanCheckScreen({ onComplete }: QuickHumanCheckScreenProps) {
  const [formData, setFormData] = useState({
    interiorCondition: "",
    tireCondition: "",
    dashboardLights: null as boolean | null,
    engineSounds: null as boolean | null,
  });
  
  const [selectedWarningLights, setSelectedWarningLights] = useState<string[]>([]);

  const warningLightOptions = [
    { id: "oil", label: "Oil", icon: Droplet },
    { id: "check-engine", label: "Check Engine", icon: AlertTriangle },
    { id: "tire-pressure", label: "Tire Pressure", icon: Wind },
    { id: "washer-fluid", label: "Washer Fluid", icon: Droplets },
    { id: "abs", label: "ABS", icon: Disc },
    { id: "radiator", label: "Radiator", icon: Thermometer },
    { id: "battery", label: "Battery", icon: Battery },
    { id: "airbag", label: "AirBag", icon: Shield },
    { id: "other", label: "Other", icon: MoreHorizontal },
  ];

  const toggleWarningLight = (id: string) => {
    setSelectedWarningLights(prev => 
      prev.includes(id) 
        ? prev.filter(item => item !== id)
        : [...prev, id]
    );
  };

  const handleSubmit = () => {
    onComplete({
      interiorCondition: formData.interiorCondition,
      tireCondition: formData.tireCondition,
      dashboardLights: formData.dashboardLights ?? false,
      warningLightTypes: formData.dashboardLights ? selectedWarningLights : undefined,
      engineSounds: formData.engineSounds ?? false,
    });
  };

  const handleSkip = () => {
    onComplete({
      interiorCondition: "",
      tireCondition: "",
      dashboardLights: false,
      engineSounds: false,
    });
  };

  const allAnswered =
    formData.interiorCondition !== "" &&
    formData.tireCondition !== "" &&
    formData.dashboardLights !== null &&
    formData.engineSounds !== null &&
    (formData.dashboardLights === false || selectedWarningLights.length > 0);

  return (
    <div className="min-h-screen bg-[#F8F8F7] flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-[#E5E5E5]">
        <div className="max-w-md mx-auto px-6 py-4">
          <h1 className="text-center text-[#1A1A1A]" style={{ fontSize: '17px', fontWeight: 600 }}>
            Quick Check
          </h1>
        </div>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="max-w-md mx-auto px-6 py-8">
          <p className="mb-8 text-[#666666] leading-relaxed" style={{ fontSize: '15px' }}>
            Answer a few quick questions about the vehicle’s current condition.
          </p>

          <div className="space-y-8">
            {/* Interior Condition */}
            <div>
              <p className="mb-3 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                How would you rate the interior condition?
              </p>
              <div className="grid grid-cols-3 gap-2">
                {["Good", "Worn", "Poor"].map((option) => (
                  <button
                    key={option}
                    onClick={() => setFormData({ ...formData, interiorCondition: option })}
                    className={`h-11 rounded border transition-all ${
                      formData.interiorCondition === option
                        ? "border-[#3EB489] bg-[#3EB489] text-white"
                        : "border-[#E5E5E5] bg-white text-[#1A1A1A]"
                    }`}
                    style={{ fontSize: '15px', fontWeight: 600 }}
                  >
                    {option}
                  </button>
                ))}
              </div>
            </div>

            {/* Tire Condition */}
            <div>
              <p className="mb-3 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                What is the tire tread condition?
              </p>
              <div className="grid grid-cols-3 gap-2">
                {["Good", "Worn", "Bare"].map((option) => (
                  <button
                    key={option}
                    onClick={() => setFormData({ ...formData, tireCondition: option })}
                    className={`h-11 rounded border transition-all ${
                      formData.tireCondition === option
                        ? "border-[#3EB489] bg-[#3EB489] text-white"
                        : "border-[#E5E5E5] bg-white text-[#1A1A1A]"
                    }`}
                    style={{ fontSize: '15px', fontWeight: 600 }}
                  >
                    {option}
                  </button>
                ))}
              </div>
            </div>

            {/* Dashboard Lights */}
            <div>
              <p className="mb-3 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                Any warning lights on the dashboard?
              </p>
              <div className="grid grid-cols-2 gap-2">
                <button
                  onClick={() => {
                    setFormData({ ...formData, dashboardLights: true });
                  }}
                  className={`h-11 rounded border transition-all ${
                    formData.dashboardLights === true
                      ? "border-[#3EB489] bg-[#3EB489] text-white"
                      : "border-[#E5E5E5] bg-white text-[#1A1A1A]"
                  }`}
                  style={{ fontSize: '15px', fontWeight: 600 }}
                >
                  Yes
                </button>
                <button
                  onClick={() => {
                    setFormData({ ...formData, dashboardLights: false });
                    setSelectedWarningLights([]);
                  }}
                  className={`h-11 rounded border transition-all ${
                    formData.dashboardLights === false
                      ? "border-[#3EB489] bg-[#3EB489] text-white"
                      : "border-[#E5E5E5] bg-white text-[#1A1A1A]"
                  }`}
                  style={{ fontSize: '15px', fontWeight: 600 }}
                >
                  No
                </button>
              </div>
            </div>

            {/* Warning Light Types */}
            {formData.dashboardLights && (
              <div>
                <p className="mb-3 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  Which warning lights are on?
                </p>
                <div className="grid grid-cols-3 gap-2">
                  {warningLightOptions.map((option) => {
                    const Icon = option.icon;
                    return (
                      <button
                        key={option.id}
                        onClick={() => toggleWarningLight(option.id)}
                        className={`aspect-square rounded border transition-all flex flex-col items-center justify-center gap-1 p-2 ${
                          selectedWarningLights.includes(option.id)
                            ? "border-[#3EB489] bg-[#3EB489] text-white"
                            : "border-[#E5E5E5] bg-white text-[#1A1A1A]"
                        }`}
                      >
                        <Icon size={20} strokeWidth={2} />
                        <span style={{ fontSize: '11px', fontWeight: 600, lineHeight: '1.2', textAlign: 'center' }}>
                          {option.label}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Engine Sounds */}
            <div>
              <p className="mb-3 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                Any unusual engine sounds or vibrations?
              </p>
              <div className="grid grid-cols-2 gap-2">
                <button
                  onClick={() => setFormData({ ...formData, engineSounds: true })}
                  className={`h-11 rounded border transition-all ${
                    formData.engineSounds === true
                      ? "border-[#3EB489] bg-[#3EB489] text-white"
                      : "border-[#E5E5E5] bg-white text-[#1A1A1A]"
                  }`}
                  style={{ fontSize: '15px', fontWeight: 600 }}
                >
                  Yes
                </button>
                <button
                  onClick={() => setFormData({ ...formData, engineSounds: false })}
                  className={`h-11 rounded border transition-all ${
                    formData.engineSounds === false
                      ? "border-[#3EB489] bg-[#3EB489] text-white"
                      : "border-[#E5E5E5] bg-white text-[#1A1A1A]"
                  }`}
                  style={{ fontSize: '15px', fontWeight: 600 }}
                >
                  No / Not Sure
                </button>
              </div>
            </div>
          </div>

          {/* Note */}
          <div className="mt-8 bg-[#FCFCFB] border border-[#E5E5E5] rounded p-4">
            <p className="text-[#666666] leading-relaxed" style={{ fontSize: '14px' }}>
              These details help refine the value, but the vehicle data is what matters most.
            </p>
          </div>
        </div>
      </div>

      {/* Sticky Bottom Buttons */}
      <div className="bg-[#F8F8F7] border-t border-[#E5E5E5]">
        <div className="max-w-md mx-auto px-6 py-4 space-y-3 bg-white">
          <Button
            onClick={handleSubmit}
            disabled={!allAnswered}
            className="w-full h-12 bg-[#3EB489] hover:bg-[#2D9970] text-white disabled:bg-[#E5E5E5] disabled:text-[#999999] rounded"
            style={{ fontWeight: 600 }}
          >
            Continue
          </Button>
          <button
            onClick={handleSkip}
            className="w-full text-center text-[#666666] transition-colors"
            style={{ fontSize: '15px', fontWeight: 600 }}
          >
            Skip this step
          </button>
        </div>
      </div>
    </div>
  );
}
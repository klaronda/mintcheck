import { useState } from "react";
import { Button } from "@/app/components/ui/button";
import { Input } from "@/app/components/ui/input";
import { Label } from "@/app/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/app/components/ui/select";
import { ArrowLeft, Camera, Keyboard, HelpCircle } from "lucide-react";
import vinLocationImage from "figma:asset/5aefb724e77c148c11c74b3d161ec73bc433a62f.png";

interface VehicleBasicsScreenProps {
  onBack: () => void;
  onNext: (data: { make: string; model: string; year: string; vin?: string }) => void;
}

export function VehicleBasicsScreen({ onBack, onNext }: VehicleBasicsScreenProps) {
  const [currentStep, setCurrentStep] = useState<"vin-options" | "vin-manual" | "vin-scan" | "make-model">("vin-options");
  const [vinNumber, setVinNumber] = useState("");
  const [formData, setFormData] = useState({
    make: "",
    model: "",
    year: "",
  });

  // Popular car makes
  const carMakes = [
    "Acura", "Audi", "BMW", "Buick", "Cadillac", "Chevrolet", "Chrysler", 
    "Dodge", "Ford", "GMC", "Honda", "Hyundai", "Infiniti", "Jeep", 
    "Kia", "Lexus", "Lincoln", "Mazda", "Mercedes-Benz", "Mitsubishi",
    "Nissan", "Ram", "Subaru", "Tesla", "Toyota", "Volkswagen", "Volvo"
  ];

  // Models by make (sample data)
  const carModels: Record<string, string[]> = {
    Toyota: ["Camry", "Corolla", "RAV4", "Highlander", "4Runner", "Tacoma", "Tundra", "Prius", "Sienna"],
    Honda: ["Accord", "Civic", "CR-V", "Pilot", "Odyssey", "Ridgeline", "HR-V", "Passport"],
    Ford: ["F-150", "Escape", "Explorer", "Mustang", "Edge", "Expedition", "Bronco", "Ranger"],
    Chevrolet: ["Silverado", "Equinox", "Malibu", "Traverse", "Tahoe", "Colorado", "Camaro", "Blazer"],
    Nissan: ["Altima", "Rogue", "Sentra", "Pathfinder", "Frontier", "Murano", "Armada", "Maxima"],
    Jeep: ["Wrangler", "Grand Cherokee", "Cherokee", "Compass", "Gladiator", "Renegade"],
    Hyundai: ["Elantra", "Sonata", "Tucson", "Santa Fe", "Kona", "Palisade", "Venue"],
    Subaru: ["Outback", "Forester", "Crosstrek", "Impreza", "Ascent", "Legacy", "WRX"],
    Mazda: ["CX-5", "Mazda3", "CX-9", "CX-30", "Mazda6", "MX-5 Miata"],
    BMW: ["3 Series", "5 Series", "X3", "X5", "7 Series", "X1", "4 Series"],
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (formData.make && formData.model) {
      onNext(formData);
    }
  };

  const handleVinSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (vinNumber.length === 17) {
      // In a real app, decode VIN here to get make/model/year
      // For now, just proceed to next screen
      onNext({ make: "Toyota", model: "Camry", year: "2018", vin: vinNumber });
    }
  };

  const handleCameraCapture = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      // In a real app, process the image to extract VIN
      // For now, just show manual entry
      setCurrentStep("vin-manual");
    }
  };

  const handleBackNavigation = () => {
    if (currentStep === "vin-options") {
      onBack();
    } else {
      setCurrentStep("vin-options");
    }
  };

  const availableModels = formData.make && carModels[formData.make] ? carModels[formData.make] : [];

  return (
    <div className="min-h-screen bg-[#F8F8F7] flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-[#E5E5E5]">
        <div className="max-w-md mx-auto px-6 py-4 flex items-center">
          <button
            onClick={handleBackNavigation}
            className="p-2 -ml-2 text-[#666666] hover:text-[#1A1A1A] transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <h1 className="flex-1 text-center pr-8 text-[#1A1A1A]" style={{ fontSize: '17px', fontWeight: 600 }}>
            Vehicle Information
          </h1>
        </div>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto pb-24">
        <div className="px-6 pt-8 max-w-md mx-auto w-full">
          {/* VIN Options Step */}
          {currentStep === "vin-options" && (
            <>
              <div className="mb-6">
                <h2 className="mb-2 text-[#1A1A1A]" style={{ fontSize: '20px', fontWeight: 600 }}>
                  Enter Vehicle Identification Number
                </h2>
                <p className="text-[#666666] leading-relaxed" style={{ fontSize: '15px' }}>
                  The fastest way to identify your vehicle is with the 17-character VIN.
                </p>
              </div>

              {/* VIN Location Image */}
              <div className="mb-6 rounded overflow-hidden border border-[#E5E5E5] bg-white">
                <img
                  src={vinLocationImage}
                  alt="VIN location on vehicle"
                  className="w-full h-auto"
                />
              </div>

              <div className="space-y-3">
                {/* Scan VIN with Camera */}
                <label className="block">
                  <input
                    type="file"
                    accept="image/*"
                    capture="environment"
                    onChange={handleCameraCapture}
                    className="hidden"
                    id="camera-input"
                  />
                  <div className="w-full bg-white border border-[#E5E5E5] rounded p-4 hover:border-[#1A1A1A] transition-all cursor-pointer">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded bg-[#F8F8F7] flex items-center justify-center flex-shrink-0">
                        <Camera className="w-5 h-5 text-[#1A1A1A]" strokeWidth={2} />
                      </div>
                      <div className="flex-1">
                        <p className="text-[#1A1A1A] mb-0.5" style={{ fontSize: '15px', fontWeight: 600 }}>
                          Scan VIN with Camera
                        </p>
                        <p className="text-[#666666]" style={{ fontSize: '13px', fontWeight: 400 }}>
                          Point your camera at the VIN
                        </p>
                      </div>
                    </div>
                  </div>
                </label>

                {/* Enter VIN Manually */}
                <button
                  type="button"
                  onClick={() => setCurrentStep("vin-manual")}
                  className="w-full bg-white border border-[#E5E5E5] rounded p-4 hover:border-[#1A1A1A] transition-all text-left"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded bg-[#F8F8F7] flex items-center justify-center flex-shrink-0">
                      <Keyboard className="w-5 h-5 text-[#1A1A1A]" strokeWidth={2} />
                    </div>
                    <div className="flex-1">
                      <p className="text-[#1A1A1A] mb-0.5" style={{ fontSize: '15px', fontWeight: 600 }}>
                        Enter VIN Manually
                      </p>
                      <p className="text-[#666666]" style={{ fontSize: '13px', fontWeight: 400 }}>
                        Type in the 17-character VIN
                      </p>
                    </div>
                  </div>
                </button>

                {/* Can't Find VIN */}
                <button
                  type="button"
                  onClick={() => setCurrentStep("make-model")}
                  className="w-full bg-white border border-[#E5E5E5] rounded p-4 hover:border-[#1A1A1A] transition-all text-left"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded bg-[#F8F8F7] flex items-center justify-center flex-shrink-0">
                      <HelpCircle className="w-5 h-5 text-[#1A1A1A]" strokeWidth={2} />
                    </div>
                    <div className="flex-1">
                      <p className="text-[#1A1A1A] mb-0.5" style={{ fontSize: '15px', fontWeight: 600 }}>
                        I can’t find the VIN number
                      </p>
                      <p className="text-[#666666]" style={{ fontSize: '13px', fontWeight: 400 }}>
                        Enter make, model, and year instead
                      </p>
                    </div>
                  </div>
                </button>
              </div>

              {/* Info Tooltip */}
              <div className="bg-[#F8F8F7] rounded p-4 mt-6 border border-[#E5E5E5]">
                <p className="text-[#666666] leading-relaxed" style={{ fontSize: '14px' }}>
                  <strong className="text-[#1A1A1A] font-semibold">Why do we need this?</strong><br />
                  The VIN number will tell us the exact make, model, year and trim of the car so there's no surprises later.
                </p>
              </div>
            </>
          )}

          {/* Manual VIN Entry Step */}
          {currentStep === "vin-manual" && (
            <>
              <div className="mb-6">
                <h2 className="mb-2 text-[#1A1A1A]" style={{ fontSize: '20px', fontWeight: 600 }}>
                  Enter VIN
                </h2>
                <p className="text-[#666666] leading-relaxed" style={{ fontSize: '15px' }}>
                  The VIN is typically found on the driver's side dashboard (visible through windshield) or on the driver's door jamb.
                </p>
              </div>

              {/* VIN Location Image */}
              <div className="mb-6 rounded overflow-hidden border border-[#E5E5E5] bg-white">
                <img
                  src={vinLocationImage}
                  alt="VIN location on vehicle"
                  className="w-full h-auto"
                />
              </div>

              <form onSubmit={handleVinSubmit} className="space-y-5">
                <div className="space-y-1.5">
                  <Label htmlFor="vin" className="text-[#1A1A1A]">
                    Vehicle Identification Number <span className="text-[#DC3545]">*</span>
                  </Label>
                  <Input
                    id="vin"
                    type="text"
                    placeholder="1HGBH41JXMN109186"
                    value={vinNumber}
                    onChange={(e) => setVinNumber(e.target.value.toUpperCase())}
                    className="h-11 bg-white placeholder:text-[#999999] border-[#E5E5E5] rounded font-mono"
                    maxLength={17}
                    style={{ fontSize: '15px' }}
                  />
                  <p className="text-[#666666] pt-1" style={{ fontSize: '13px', fontWeight: 400 }}>
                    {vinNumber.length}/17 characters
                  </p>
                </div>
              </form>
            </>
          )}

          {/* Make/Model/Year Step */}
          {currentStep === "make-model" && (
            <>
              <div className="mb-8">
                <h2 className="mb-2 text-[#1A1A1A]" style={{ fontSize: '20px', fontWeight: 600 }}>
                  Vehicle Details
                </h2>
                <p className="text-[#666666] leading-relaxed" style={{ fontSize: '15px' }}>
                  Tell us the make, model, and year of the vehicle you're checking.
                </p>
              </div>

              <form onSubmit={handleSubmit} className="space-y-5">
                <div className="space-y-1.5">
                  <Label htmlFor="make" className="text-[#1A1A1A]">
                    Make <span className="text-[#DC3545]">*</span>
                  </Label>
                  <Select
                    value={formData.make}
                    onValueChange={(value) => {
                      setFormData({ ...formData, make: value, model: "" });
                    }}
                  >
                    <SelectTrigger className="h-11 bg-white border-[#E5E5E5] rounded">
                      <SelectValue placeholder="Select make" />
                    </SelectTrigger>
                    <SelectContent>
                      {carMakes.map((make) => (
                        <SelectItem key={make} value={make}>
                          {make}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-1.5">
                  <Label htmlFor="model" className="text-[#1A1A1A]">
                    Model <span className="text-[#DC3545]">*</span>
                  </Label>
                  <Select
                    value={formData.model}
                    onValueChange={(value) => setFormData({ ...formData, model: value })}
                    disabled={!formData.make}
                  >
                    <SelectTrigger className="h-11 bg-white border-[#E5E5E5] rounded">
                      <SelectValue placeholder={formData.make ? "Select model" : "Select make first"} />
                    </SelectTrigger>
                    <SelectContent>
                      {availableModels.length > 0 ? (
                        availableModels.map((model) => (
                          <SelectItem key={model} value={model}>
                            {model}
                          </SelectItem>
                        ))
                      ) : (
                        <SelectItem value="other">Other</SelectItem>
                      )}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-1.5">
                  <Label htmlFor="year" className="text-[#1A1A1A]">Year</Label>
                  <Input
                    id="year"
                    type="text"
                    placeholder="2018"
                    value={formData.year}
                    onChange={(e) => setFormData({ ...formData, year: e.target.value })}
                    className="h-11 bg-white placeholder:text-[#999999] border-[#E5E5E5] rounded"
                    maxLength={4}
                  />
                </div>
              </form>
            </>
          )}
        </div>
      </div>

      {/* Sticky Bottom Button */}
      {(currentStep === "vin-manual" || currentStep === "make-model") && (
        <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-[#E5E5E5] px-6 py-4">
          <div className="max-w-md mx-auto">
            <Button
              type="submit"
              onClick={currentStep === "vin-manual" ? handleVinSubmit : handleSubmit}
              className="w-full h-12 bg-[#3EB489] hover:bg-[#2D9970] text-white rounded"
              style={{ fontWeight: 600 }}
              disabled={currentStep === "vin-manual" ? vinNumber.length !== 17 : !formData.make || !formData.model}
            >
              Continue
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
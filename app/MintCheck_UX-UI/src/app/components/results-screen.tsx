import { Button } from "@/app/components/ui/button";
import { CheckCircle2, AlertCircle, XCircle, Share2, Home, ChevronDown, ChevronUp } from "lucide-react";
import { useState } from "react";

interface ResultsScreenProps {
  vehicleInfo: { 
    make: string; 
    model: string; 
    year: string;
    vin?: string;
    trim?: string;
    fuelType?: string;
    engine?: string;
    transmission?: string;
    drivetrain?: string;
  };
  vinDecoded?: boolean;
  recommendation: "safe" | "caution" | "not-recommended";
  onViewDetails: (section: string) => void;
  onShare: () => void;
  onReturnHome: () => void;
}

export function ResultsScreen({
  vehicleInfo,
  vinDecoded,
  recommendation,
  onShare,
  onReturnHome,
}: ResultsScreenProps) {
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>({});

  const toggleSection = (section: string) => {
    setExpandedSections((prev) => ({ ...prev, [section]: !prev[section] }));
  };

  const recommendationConfig = {
    safe: {
      icon: CheckCircle2,
      color: "#3EB489",
      bgColor: "#E6F4EE",
      title: "Safe to Buy",
      summary:
        "Based on the scan, this vehicle's engine and core systems appear to be in good condition. No major concerns were found.",
    },
    caution: {
      icon: AlertCircle,
      color: "#E3B341",
      bgColor: "#FFF9E6",
      title: "Proceed with Caution",
      summary:
        "The scan found some items that need attention. Review the details below and consider having a mechanic inspect the vehicle before buying.",
    },
    "not-recommended": {
      icon: XCircle,
      color: "#C94A4A",
      bgColor: "#FFE6E6",
      title: "Not Recommended",
      summary:
        "The scan found significant concerns with this vehicle's systems. We recommend looking at other options or getting a professional inspection before proceeding.",
    },
  };

  const config = recommendationConfig[recommendation];
  const Icon = config.icon;

  // Mock data for results
  const keyFindings =
    recommendation === "safe"
      ? [
          "No trouble codes found",
          "Engine temperature normal",
          "Fuel system operating correctly",
          "Emissions system functioning properly",
        ]
      : recommendation === "caution"
      ? [
          "Some systems haven't completed self-checks yet",
          "Fuel system compensating more than expected",
          "One emissions monitor not ready",
        ]
      : [
          "Multiple engine trouble codes detected",
          "Fuel system showing irregular patterns",
          "Emissions system not functioning properly",
          "Temperature controls showing concerns",
        ];

  const priceRange =
    recommendation === "safe"
      ? "$15,000 - $17,000"
      : recommendation === "caution"
      ? "$13,000 - $15,000"
      : "$10,000 - $12,000";

  const priceNote =
    recommendation === "safe"
      ? "The asking price appears fair for this condition."
      : recommendation === "caution"
      ? "Consider negotiating based on repair needs."
      : "The asking price appears high for this condition.";

  const repairEstimate =
    recommendation === "caution"
      ? "Issues like these typically cost $800 - $2,500 to repair."
      : recommendation === "not-recommended"
      ? "Issues like these typically cost $2,500 - $5,000+ to repair."
      : null;

  // System details
  const systemDetails = {
    engine: {
      name: "Engine",
      status: recommendation === "safe" ? "Good" : "Needs Attention",
      color: recommendation === "safe" ? "#3EB489" : "#E3B341",
      details:
        recommendation === "safe"
          ? [
              "No trouble codes detected",
              "All sensors responding correctly",
              "Timing and performance normal",
            ]
          : [
              "3 trouble codes detected",
              "P0171 - Fuel system too lean",
              "P0300 - Random cylinder misfire detected",
            ],
      explanation:
        recommendation === "safe"
          ? "The engine is operating normally with no issues detected."
          : "The engine has some trouble codes that need attention. These may affect performance or reliability.",
    },
    fuel: {
      name: "Fuel System",
      status: recommendation === "not-recommended" ? "Needs Attention" : "Good",
      color: recommendation === "not-recommended" ? "#E3B341" : "#3EB489",
      details:
        recommendation === "not-recommended"
          ? ["Fuel trim values outside normal range", "System compensating by +15%", "Possible vacuum leak or filter issue"]
          : ["Fuel pressure within spec", "No leaks detected", "Injectors operating correctly"],
      explanation:
        recommendation === "not-recommended"
          ? "The fuel system is compensating for an issue. This could be a leak, clog, or sensor problem."
          : "The fuel system is delivering the correct amount of fuel and maintaining proper pressure.",
    },
    emissions: {
      name: "Emissions",
      status: recommendation === "not-recommended" ? "Needs Attention" : "Good",
      color: recommendation === "not-recommended" ? "#E3B341" : "#3EB489",
      details:
        recommendation === "not-recommended"
          ? ["Catalytic converter efficiency below threshold", "2 emissions monitors not ready", "May fail emissions testing"]
          : ["Catalytic converter functioning normally", "All emissions monitors ready", "Should pass emissions testing"],
      explanation:
        recommendation === "not-recommended"
          ? "Some emissions systems are not functioning properly. This could cause the vehicle to fail emissions testing."
          : "All emissions systems are functioning correctly.",
    },
    electrical: {
      name: "Electrical",
      status: "Good",
      color: "#3EB489",
      details: ["Battery voltage healthy", "All electrical sensors responding", "No wiring issues detected"],
      explanation: "The electrical system is functioning properly.",
    },
  };

  return (
    <div className="min-h-screen bg-[#F8F8F7] pb-24">
      {/* Header */}
      <div className="bg-white sticky top-0 z-10 border-b border-[#E5E5E5]">
        <div className="max-w-2xl mx-auto px-6 py-5">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-[#1A1A1A] mb-0.5" style={{ fontSize: '18px', fontWeight: 600 }}>Vehicle Scan Report</h1>
              <p className="text-[#666666] mt-1" style={{ fontSize: '14px' }}>
                {vehicleInfo.year} {vehicleInfo.make} {vehicleInfo.model}
              </p>
            </div>
            <button onClick={onShare} className="p-2 text-[#666666] hover:text-[#1A1A1A] rounded transition-colors">
              <Share2 className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-2xl mx-auto px-6 py-8">
        {/* Recommendation Badge */}
        <div
          className="border-2 rounded p-6 mb-8"
          style={{ backgroundColor: config.bgColor, borderColor: config.color }}
        >
          <div className="flex items-center gap-4 mb-3">
            <div
              className="w-12 h-12 rounded flex items-center justify-center flex-shrink-0"
              style={{ backgroundColor: config.color }}
            >
              <Icon className="w-6 h-6 text-white" strokeWidth={2} />
            </div>
            <div className="flex-1">
              <h2 className="mb-0" style={{ fontSize: '22px', fontWeight: 600, color: config.color }}>
                {config.title}
              </h2>
            </div>
          </div>
          <p className="text-[#1A1A1A] leading-relaxed" style={{ fontSize: '15px' }}>
            {config.summary}
          </p>
        </div>

        {/* Vehicle Details Card */}
        <div className="bg-white border border-[#E5E5E5] rounded p-6 mb-6">
          <h3 className="mb-4 pb-4 border-b border-[#E5E5E5] text-[#1A1A1A]" style={{ fontSize: '17px', fontWeight: 600 }}>
            Vehicle Details
          </h3>

          <div className="space-y-3">
            {vehicleInfo.vin && (
              <div className="flex justify-between items-start">
                <span className="text-[#666666]" style={{ fontSize: '15px' }}>VIN</span>
                <span className="text-[#1A1A1A] text-right font-mono" style={{ fontSize: '14px', fontWeight: 600 }}>
                  {vehicleInfo.vin}
                </span>
              </div>
            )}
            
            <div className="flex justify-between items-start">
              <span className="text-[#666666]" style={{ fontSize: '15px' }}>Year</span>
              <span className="text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                {vehicleInfo.year}
              </span>
            </div>

            <div className="flex justify-between items-start">
              <span className="text-[#666666]" style={{ fontSize: '15px' }}>Make</span>
              <span className="text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                {vehicleInfo.make}
              </span>
            </div>

            <div className="flex justify-between items-start">
              <span className="text-[#666666]" style={{ fontSize: '15px' }}>Model</span>
              <span className="text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                {vehicleInfo.model}
              </span>
            </div>

            {vehicleInfo.trim && (
              <div className="flex justify-between items-start">
                <span className="text-[#666666]" style={{ fontSize: '15px' }}>Trim</span>
                <span className="text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  {vehicleInfo.trim}
                </span>
              </div>
            )}

            {vehicleInfo.fuelType && (
              <div className="flex justify-between items-start">
                <span className="text-[#666666]" style={{ fontSize: '15px' }}>Fuel Type</span>
                <span className="text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  {vehicleInfo.fuelType}
                </span>
              </div>
            )}

            {vehicleInfo.engine && (
              <div className="flex justify-between items-start">
                <span className="text-[#666666]" style={{ fontSize: '15px' }}>Engine</span>
                <span className="text-[#1A1A1A] text-right" style={{ fontSize: '15px', fontWeight: 600 }}>
                  {vehicleInfo.engine}
                </span>
              </div>
            )}

            {vehicleInfo.transmission && (
              <div className="flex justify-between items-start">
                <span className="text-[#666666]" style={{ fontSize: '15px' }}>Transmission</span>
                <span className="text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  {vehicleInfo.transmission}
                </span>
              </div>
            )}

            {vehicleInfo.drivetrain && (
              <div className="flex justify-between items-start">
                <span className="text-[#666666]" style={{ fontSize: '15px' }}>Drivetrain</span>
                <span className="text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  {vehicleInfo.drivetrain}
                </span>
              </div>
            )}
          </div>

          {/* VIN Disclaimer */}
          {!vinDecoded && (
            <div className="mt-4 pt-4 border-t border-[#E5E5E5]">
              <p className="text-[#666666] leading-relaxed" style={{ fontSize: '13px' }}>
                {vehicleInfo.vin 
                  ? "VIN could not be decoded. Details shown are based on user input."
                  : "VIN was not provided. Details shown are based on user input."}
              </p>
            </div>
          )}
        </div>

        {/* Main Findings & Price */}
        <div className="bg-white border border-[#E5E5E5] rounded p-6 mb-6">
          {/* Key Findings */}
          <h3 className="mb-4 pb-4 border-b border-[#E5E5E5] text-[#1A1A1A]" style={{ fontSize: '17px', fontWeight: 600 }}>
            What We Found
          </h3>
          <ul className="space-y-2.5 mb-6">
            {keyFindings.map((finding, index) => (
              <li key={index} className="flex items-start gap-2.5">
                <div
                  className="w-1.5 h-1.5 rounded-full flex-shrink-0 mt-2"
                  style={{ backgroundColor: config.color }}
                />
                <p className="text-[#1A1A1A] leading-relaxed flex-1" style={{ fontSize: '15px' }}>
                  {finding}
                </p>
              </li>
            ))}
          </ul>

          {/* Price Context */}
          <div className="pt-6 border-t border-[#E5E5E5]">
            <h3 className="mb-3 text-[#1A1A1A]" style={{ fontSize: '16px', fontWeight: 600 }}>
              Price Context
            </h3>
            <p className="text-[#1A1A1A] mb-2 leading-relaxed" style={{ fontSize: '15px' }}>
              Similar vehicles typically list between <span className="font-semibold">{priceRange}</span> in this condition.
            </p>
            <p className="text-[#666666] leading-relaxed" style={{ fontSize: '15px' }}>
              {priceNote}
            </p>
            {repairEstimate && (
              <p className="text-[#F59E0B] mt-3 leading-relaxed" style={{ fontSize: '15px', fontWeight: 600 }}>
                {repairEstimate}
              </p>
            )}
          </div>
        </div>

        {/* System Details - Expandable */}
        <div className="bg-white border border-[#E5E5E5] rounded overflow-hidden">
          <div className="p-5 border-b border-[#E5E5E5]">
            <h3 className="text-[#1A1A1A]" style={{ fontSize: '17px', fontWeight: 600 }}>System Details</h3>
          </div>

          {Object.entries(systemDetails).map(([key, system], index) => (
            <div
              key={key}
              className={index < Object.keys(systemDetails).length - 1 ? "border-b border-[#E5E5E5]" : ""}
            >
              <button
                onClick={() => toggleSection(key)}
                className="w-full p-4 flex items-center justify-between hover:bg-[#F8F8F7] transition-colors text-left"
              >
                <div className="flex items-center gap-2.5">
                  <div className="w-2 h-2 rounded-full" style={{ backgroundColor: system.color }} />
                  <span className="text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                    {system.name}
                  </span>
                </div>
                <div className="flex items-center gap-2.5">
                  <span className="text-[#666666]" style={{ fontSize: '14px', fontWeight: 600 }}>
                    {system.status}
                  </span>
                  {expandedSections[key] ? (
                    <ChevronUp className="w-4 h-4 text-[#666666]" />
                  ) : (
                    <ChevronDown className="w-4 h-4 text-[#666666]" />
                  )}
                </div>
              </button>

              {expandedSections[key] && (
                <div className="px-4 pb-4 bg-[#F8F8F7]">
                  <p className="text-[#1A1A1A] mb-3 leading-relaxed" style={{ fontSize: '14px' }}>
                    {system.explanation}
                  </p>
                  <ul className="space-y-1.5">
                    {system.details.map((detail, idx) => (
                      <li key={idx} className="flex items-start gap-2">
                        <span className="text-[#666666] flex-shrink-0">•</span>
                        <p className="text-[#666666] leading-relaxed flex-1" style={{ fontSize: '14px' }}>
                          {detail}
                        </p>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Important Note */}
        <div className="bg-[#FCFCFB] border border-[#E5E5E5] rounded p-4 mt-6">
          <p className="text-[#666666] leading-relaxed" style={{ fontSize: '14px' }}>
            This check reviews the car’s systems. Other inspections may be needed.
          </p>
        </div>
      </div>

      {/* Fixed Bottom Actions */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-[#E5E5E5] p-6">
        <div className="max-w-2xl mx-auto">
          <Button onClick={onReturnHome} className="w-full h-12 bg-[#3EB489] hover:bg-[#2D9970] text-white rounded" style={{ fontWeight: 600 }}>
            Return to Dashboard
          </Button>
        </div>
      </div>
    </div>
  );
}
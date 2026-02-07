import { Button } from "@/app/components/ui/button";
import { ArrowLeft, CheckCircle2, AlertCircle } from "lucide-react";

interface SystemDetailScreenProps {
  section: string;
  status: "Good" | "Needs Attention";
  onBack: () => void;
}

export function SystemDetailScreen({ section, status, onBack }: SystemDetailScreenProps) {
  const isGood = status === "Good";

  const sectionData: Record<
    string,
    {
      title: string;
      explanation: string;
      whyMatters: string;
      details: string[];
    }
  > = {
    engine: {
      title: "Engine",
      explanation: isGood
        ? "The engine is operating normally with no trouble codes detected. All sensors are reporting values within expected ranges."
        : "The engine has some trouble codes that need attention. These indicate the engine control system has detected issues that may affect performance or reliability.",
      whyMatters:
        "The engine is the heart of the vehicle. Problems here can be expensive to repair and may affect safety and reliability.",
      details: isGood
        ? [
            "No diagnostic trouble codes (DTCs) detected",
            "Engine temperature within normal range",
            "All engine sensors responding correctly",
            "Timing and performance parameters normal",
          ]
        : [
            "3 diagnostic trouble codes detected",
            "P0171 - Fuel system too lean (Bank 1)",
            "P0300 - Random cylinder misfire detected",
            "Oxygen sensor readings irregular",
          ],
    },
    electrical: {
      title: "Electrical",
      explanation:
        "The electrical system is functioning properly. Battery voltage, alternator output, and all electrical sensors are working as expected.",
      whyMatters:
        "Electrical problems can cause starting issues, drain the battery, or create intermittent failures in other systems.",
      details: [
        "Battery voltage healthy",
        "Alternator charging correctly",
        "All electrical sensors responding",
        "No wiring or connection issues detected",
      ],
    },
    fuel: {
      title: "Fuel System",
      explanation: isGood
        ? "The fuel system is delivering the correct amount of fuel and maintaining proper pressure. No leaks or blockages detected."
        : "The fuel system is showing signs of irregular operation. It may be compensating for a leak, clog, or sensor issue.",
      whyMatters:
        "A properly functioning fuel system ensures good fuel economy and engine performance. Problems here can cause poor mileage or rough running.",
      details: isGood
        ? [
            "Fuel pressure within spec",
            "No fuel system leaks detected",
            "Fuel injectors operating correctly",
            "Fuel trim values normal",
          ]
        : [
            "Fuel trim values outside normal range",
            "System compensating by +15% (typical is ±5%)",
            "Possible vacuum leak or clogged filter",
            "May affect fuel economy",
          ],
    },
    emissions: {
      title: "Emissions",
      explanation: isGood
        ? "All emissions systems are functioning correctly. The vehicle should pass emissions testing in most states."
        : "Some emissions systems are not functioning properly. This could cause the vehicle to fail emissions testing and may indicate other issues.",
      whyMatters:
        "Emissions systems protect the environment and ensure the vehicle meets legal requirements. Problems may prevent registration in some states.",
      details: isGood
        ? [
            "Catalytic converter functioning normally",
            "Oxygen sensors reading correctly",
            "EVAP system (fuel vapor control) working",
            "All emissions monitors ready",
          ]
        : [
            "Catalytic converter efficiency below threshold",
            "Oxygen sensor reading slow to respond",
            "2 emissions monitors not ready",
            "May fail emissions testing",
          ],
    },
  };

  const data = sectionData[section] || sectionData.engine;

  return (
    <div className="min-h-screen bg-[#F4F5F4]">
      {/* Header */}
      <div className="bg-white border-b border-[rgba(46,46,46,0.1)]">
        <div className="max-w-2xl mx-auto px-6 py-4 flex items-center">
          <button onClick={onBack} className="p-2 -ml-2 text-[#4A4A4A] hover:text-[#2E2E2E]">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="flex-1 text-center pr-8" style={{ fontSize: '18px' }}>
            {data.title}
          </h1>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-2xl mx-auto px-6 py-6">
        {/* Status Badge */}
        <div className="flex items-center gap-2 mb-6">
          {isGood ? (
            <div className="flex items-center gap-2 bg-[#E6F4EE] px-4 py-2 rounded-full">
              <CheckCircle2 className="w-5 h-5 text-[#3EB489]" />
              <span className="text-[#3EB489]" style={{ fontSize: '15px', fontWeight: 500 }}>
                Good
              </span>
            </div>
          ) : (
            <div className="flex items-center gap-2 bg-[#FFF9E6] px-4 py-2 rounded-full">
              <AlertCircle className="w-5 h-5 text-[#E3B341]" />
              <span className="text-[#E3B341]" style={{ fontSize: '15px', fontWeight: 500 }}>
                Needs Attention
              </span>
            </div>
          )}
        </div>

        {/* Explanation */}
        <div className="bg-white rounded-xl p-6 mb-6 border border-[rgba(46,46,46,0.1)]">
          <h3 className="mb-3" style={{ fontSize: '16px', fontWeight: 500 }}>
            What This Means
          </h3>
          <p className="text-[#2E2E2E] leading-relaxed" style={{ fontSize: '15px' }}>
            {data.explanation}
          </p>
        </div>

        {/* Details */}
        <div className="bg-white rounded-xl p-6 mb-6 border border-[rgba(46,46,46,0.1)]">
          <h3 className="mb-4" style={{ fontSize: '16px', fontWeight: 500 }}>
            Technical Details
          </h3>
          <ul className="space-y-3">
            {data.details.map((detail, index) => (
              <li key={index} className="flex items-start gap-3">
                <div
                  className={`w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 ${
                    isGood ? "bg-[#E6F4EE]" : "bg-[#FFF9E6]"
                  }`}
                >
                  <div
                    className={`w-2 h-2 rounded-full ${isGood ? "bg-[#3EB489]" : "bg-[#E3B341]"}`}
                  />
                </div>
                <p className="text-[#2E2E2E] leading-relaxed flex-1" style={{ fontSize: '15px' }}>
                  {detail}
                </p>
              </li>
            ))}
          </ul>
        </div>

        {/* Why This Matters */}
        <div className="bg-[#E6F4EE] rounded-xl p-6">
          <h3 className="mb-3" style={{ fontSize: '16px', fontWeight: 500 }}>
            Why This Matters
          </h3>
          <p className="text-[#2E2E2E] leading-relaxed" style={{ fontSize: '15px' }}>
            {data.whyMatters}
          </p>
        </div>
      </div>
    </div>
  );
}

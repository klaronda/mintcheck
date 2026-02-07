import { useState } from "react";
import { Button } from "@/app/components/ui/button";
import { ArrowLeft, Wifi, Bluetooth, X } from "lucide-react";
import obdPortImage from "figma:asset/41417799361e5f51b147a5615655e4257a5f3542.png";

interface DeviceConnectionScreenProps {
  onBack: () => void;
  onConnect: (deviceType: "wifi" | "bluetooth") => void;
}

export function DeviceConnectionScreen({ onBack, onConnect }: DeviceConnectionScreenProps) {
  const [selectedType, setSelectedType] = useState<"wifi" | "bluetooth" | null>(null);
  const [showObdModal, setShowObdModal] = useState(false);

  const handleConnect = () => {
    if (selectedType) {
      // Placeholder for native picker - in Swift app, this will trigger native UI
      if (selectedType === "wifi") {
        // Native Wi-Fi picker would open here
        console.log("Native Wi-Fi picker would open here");
        alert("In the native app, this will open your device's Wi-Fi settings to connect to your scanner.");
      } else {
        // Native Bluetooth picker would open here
        console.log("Native Bluetooth picker would open here");
        alert("In the native app, this will open your device's Bluetooth settings to pair with your scanner.");
      }
      onConnect(selectedType);
    }
  };

  return (
    <div className="min-h-screen bg-[#F8F8F7] flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-[#E5E5E5]">
        <div className="max-w-md mx-auto px-6 py-4 flex items-center">
          <button
            onClick={onBack}
            className="p-2 -ml-2 text-[#666666] hover:text-[#1A1A1A]"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <h1 className="flex-1 text-center pr-8 text-[#1A1A1A]" style={{ fontSize: '17px', fontWeight: 600 }}>
            Connect Scanner
          </h1>
        </div>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto pb-24">
        <div className="px-6 pt-8 max-w-md mx-auto w-full">
          {/* Headline */}
          <h2 className="mb-4 text-[#1A1A1A]" style={{ fontSize: '20px', fontWeight: 600 }}>
            Plug in your vehicle scanner.
          </h2>

          {/* OBD-II Port Image */}
          <div className="mb-6 rounded overflow-hidden border border-[#E5E5E5]">
            <img
              src={obdPortImage}
              alt="OBD-II port location diagram"
              className="w-full h-auto"
            />
          </div>

          <div className="mb-6">
            <p className="text-[#666666] leading-relaxed" style={{ fontSize: '15px' }}>
              Connect your OBD-II device into the vehicle’s port (usually under the dashboard on the driver’s side).
            </p>
            <button
              type="button"
              onClick={() => setShowObdModal(true)}
              className="text-[#666666] hover:text-[#1A1A1A] pt-3 transition-colors"
              style={{ fontSize: '14px', fontWeight: 600 }}
            >
              Help me find the OBD-II port on this vehicle.
            </button>
          </div>

          {/* Device Type Selection */}
          <div className="space-y-2.5 mb-6">
            <button
              onClick={() => setSelectedType("wifi")}
              className={`w-full p-4 rounded border-2 transition-all text-left ${
                selectedType === "wifi"
                  ? "border-[#3EB489] bg-white"
                  : "border-[#E5E5E5] bg-white"
              }`}
            >
              <div className="flex items-start gap-3">
                <div
                  className={`w-9 h-9 rounded flex items-center justify-center ${
                    selectedType === "wifi" ? "bg-[#3EB489]" : "bg-[#F8F8F7]"
                  }`}
                >
                  <Wifi className={selectedType === "wifi" ? "text-white w-5 h-5" : "text-[#666666] w-5 h-5"} strokeWidth={2} />
                </div>
                <div className="flex-1">
                  <p className="mb-0.5 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                    Wi-Fi Scanner
                  </p>
                  <p className="text-[#666666]" style={{ fontSize: '13px', fontWeight: 400 }}>
                    Recommended. Connect to the scanner’s Wi-Fi network.
                  </p>
                </div>
              </div>
            </button>

            <button
              onClick={() => setSelectedType("bluetooth")}
              className={`w-full p-4 rounded border-2 transition-all text-left ${
                selectedType === "bluetooth"
                  ? "border-[#3EB489] bg-white"
                  : "border-[#E5E5E5] bg-white"
              }`}
            >
              <div className="flex items-start gap-3">
                <div
                  className={`w-9 h-9 rounded flex items-center justify-center ${
                    selectedType === "bluetooth" ? "bg-[#3EB489]" : "bg-[#F8F8F7]"
                  }`}
                >
                  <Bluetooth className={selectedType === "bluetooth" ? "text-white w-5 h-5" : "text-[#666666] w-5 h-5"} strokeWidth={2} />
                </div>
                <div className="flex-1">
                  <p className="mb-0.5 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                    Bluetooth Scanner
                  </p>
                  <p className="text-[#666666]" style={{ fontSize: '13px', fontWeight: 400 }}>
                    Pair with your scanner via Bluetooth settings.
                  </p>
                </div>
              </div>
            </button>
          </div>

          {/* Wi-Fi Instructions */}
          {selectedType === "wifi" && (
            <div className="bg-white border border-[#E5E5E5] rounded p-4 mb-6">
              <p className="mb-3 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                Connection Steps:
              </p>
              <ol className="space-y-2 text-[#666666] list-decimal pl-5" style={{ fontSize: '14px' }}>
                <li className="pl-2">Turn on the vehicle’s ignition</li>
                <li className="pl-2">Go to your phone’s Wi-Fi settings</li>
                <li className="pl-2">Connect to your scanner’s Wi-Fi network</li>
                <li className="pl-2">Return to this app</li>
              </ol>
            </div>
          )}

          {/* Bluetooth Instructions */}
          {selectedType === "bluetooth" && (
            <div className="bg-white border border-[#E5E5E5] rounded p-4 mb-6">
              <p className="mb-3 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                Connection Steps:
              </p>
              <ol className="space-y-2 text-[#666666] list-decimal pl-5" style={{ fontSize: '14px' }}>
                <li className="pl-2">Turn on the vehicle’s ignition</li>
                <li className="pl-2">Go to your phone’s Bluetooth settings</li>
                <li className="pl-2">Pair with your OBD-II scanner</li>
                <li className="pl-2">Return to this app</li>
              </ol>
            </div>
          )}
        </div>
      </div>

      {/* Sticky Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-[#E5E5E5] px-6 py-4">
        <div className="max-w-md mx-auto">
          <Button
            onClick={handleConnect}
            disabled={!selectedType}
            className="w-full h-12 bg-[#3EB489] hover:bg-[#2D9970] text-white disabled:opacity-50 disabled:cursor-not-allowed rounded"
            style={{ fontWeight: 600 }}
          >
            I’m Connected – Start Scan
          </Button>
        </div>
      </div>

      {/* OBD-II Port Help Modal */}
      {showObdModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center">
          <div className="bg-white w-full sm:max-w-2xl sm:rounded max-h-[90vh] flex flex-col">
            {/* Modal Header */}
            <div className="sticky top-0 bg-white px-6 py-4 flex items-center justify-between border-b border-[#E5E5E5] sm:rounded-t">
              <h2 className="text-[#1A1A1A]" style={{ fontSize: '17px', fontWeight: 600 }}>
                Finding Your OBD-II Port
              </h2>
              <button
                onClick={() => setShowObdModal(false)}
                className="p-2 -mr-2 text-[#666666] hover:text-[#1A1A1A] transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Content - Scrollable */}
            <div className="flex-1 overflow-y-auto px-6 py-6">
              {/* Hero Image */}
              <div className="mb-6 rounded overflow-hidden border border-[#E5E5E5]">
                <img
                  src={obdPortImage}
                  alt="OBD-II port location diagram"
                  className="w-full h-auto"
                />
              </div>

              {/* Content */}
              <div className="space-y-5">
                <div>
                  <h3 className="mb-2 text-[#1A1A1A]" style={{ fontSize: '16px', fontWeight: 600 }}>
                    Where is the OBD-II Port?
                  </h3>
                  <p className="text-[#666666] leading-relaxed" style={{ fontSize: '15px' }}>
                    The OBD-II port is a standardized 16-pin connector found in all cars manufactured after 1996. 
                    It’s typically located under the dashboard on the driver’s side, near the steering column.
                  </p>
                </div>

                <div>
                  <h3 className="mb-3 text-[#1A1A1A]" style={{ fontSize: '16px', fontWeight: 600 }}>
                    Common Locations
                  </h3>
                  <ul className="space-y-2 text-[#666666]" style={{ fontSize: '15px' }}>
                    <li className="flex gap-2">
                      <span className="flex-shrink-0">•</span>
                      <span className="leading-relaxed">
                        <strong className="text-[#1A1A1A] font-semibold">Most Common:</strong> Under the dashboard, left of the steering wheel
                      </span>
                    </li>
                    <li className="flex gap-2">
                      <span className="flex-shrink-0">•</span>
                      <span className="leading-relaxed">
                        <strong className="text-[#1A1A1A] font-semibold">Alternative:</strong> Under the dashboard, right of the steering wheel
                      </span>
                    </li>
                    <li className="flex gap-2">
                      <span className="flex-shrink-0">•</span>
                      <span className="leading-relaxed">
                        <strong className="text-[#1A1A1A] font-semibold">Less Common:</strong> Near the center console or behind the ashtray area
                      </span>
                    </li>
                    <li className="flex gap-2">
                      <span className="flex-shrink-0">•</span>
                      <span className="leading-relaxed">
                        <strong className="text-[#1A1A1A] font-semibold">Rare:</strong> Under the hood near the engine bay
                      </span>
                    </li>
                  </ul>
                </div>

                <div>
                  <h3 className="mb-3 text-[#1A1A1A]" style={{ fontSize: '16px', fontWeight: 600 }}>
                    Tips for Finding It
                  </h3>
                  <ul className="space-y-2 text-[#666666]" style={{ fontSize: '15px' }}>
                    <li className="flex gap-2">
                      <span className="flex-shrink-0">•</span>
                      <span className="leading-relaxed">
                        Use a flashlight to look under the dashboard
                      </span>
                    </li>
                    <li className="flex gap-2">
                      <span className="flex-shrink-0">•</span>
                      <span className="leading-relaxed">
                        It’s usually within arm's reach of the driver’s seat
                      </span>
                    </li>
                    <li className="flex gap-2">
                      <span className="flex-shrink-0">•</span>
                      <span className="leading-relaxed">
                        Check your vehicle’s owner manual for the exact location
                      </span>
                    </li>
                    <li className="flex gap-2">
                      <span className="flex-shrink-0">•</span>
                      <span className="leading-relaxed">
                        Some vehicles have a protective cover that needs to be removed
                      </span>
                    </li>
                  </ul>
                </div>

                <div className="bg-[#F8F8F7] rounded p-4 mt-6 border border-[#E5E5E5]">
                  <p className="text-[#666666] leading-relaxed" style={{ fontSize: '14px' }}>
                    <strong className="text-[#1A1A1A] font-semibold">Note:</strong> If you’re having trouble locating the port, ask the seller or check online 
                    resources for your specific vehicle make and model.
                  </p>
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="sticky bottom-0 bg-white border-t border-[#E5E5E5] px-6 py-4 sm:rounded-b">
              <Button
                onClick={() => setShowObdModal(false)}
                className="w-full h-12 bg-[#3EB489] hover:bg-[#2D9970] text-white rounded"
                style={{ fontWeight: 600 }}
              >
                Got It
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
import { Button } from "@/app/components/ui/button";
import { Plus, Clock, Star, ExternalLink } from "lucide-react";
import logoImage from "figma:asset/09d8d3854667c1081e6c375e190cf58473350d17.png";

interface DashboardScreenProps {
  onStartCheck: () => void;
  userName: string;
  scanHistory: Array<{
    id: string;
    date: string;
    vehicle: string;
    status: "safe" | "caution" | "not-recommended";
  }>;
  onViewHistory: (id: string) => void;
}

export function DashboardScreen({ onStartCheck, userName, scanHistory, onViewHistory }: DashboardScreenProps) {
  return (
    <div className="min-h-screen bg-[#F8F8F7]">
      {/* Header */}
      <div className="bg-white border-b border-[#E5E5E5]">
        <div className="max-w-2xl mx-auto px-6 py-5">
          <div className="flex items-center gap-2 mb-2">
            <img 
              src={logoImage} 
              alt="MintCheck logo" 
              className="h-7 w-auto object-contain"
            />
            <span className="text-[#1A1A1A]" style={{ fontSize: '18px', fontWeight: 600 }}>
              MintCheck
            </span>
          </div>
          <p className="text-[#666666]" style={{ fontSize: '14px' }}>
            Welcome back, {userName}
          </p>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-2xl mx-auto px-6 py-8">
        {/* Primary Action Card */}
        <div className="bg-white border border-[#E5E5E5] rounded p-6 mb-8">
          <h2 className="mb-2 text-[#1A1A1A]" style={{ fontSize: '20px', fontWeight: 600 }}>
            Ready to check a vehicle?
          </h2>
          <p className="text-[#666666] mb-6 leading-relaxed" style={{ fontSize: '15px' }}>
            Bring your OBD-II device, start a new scan, and get buying help on a used car.
          </p>
          <Button
            onClick={onStartCheck}
            className="w-full h-12 bg-[#3EB489] hover:bg-[#2D9970] text-white rounded"
            style={{ fontWeight: 600 }}
          >
            Start a Mint Check
          </Button>
        </div>

        {/* Scan History */}
        {scanHistory.length > 0 && (
          <div>
            <h3 className="mb-4 text-[#1A1A1A]" style={{ fontSize: '17px', fontWeight: 600 }}>Recent Scans</h3>

            <div className="space-y-2.5">
              {scanHistory.map((scan) => (
                <button
                  key={scan.id}
                  onClick={() => onViewHistory(scan.id)}
                  className="w-full bg-white border border-[#E5E5E5] rounded p-4 hover:border-[#1A1A1A] transition-all text-left"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex-1">
                      <p className="text-[#1A1A1A] mb-0.5" style={{ fontSize: '15px', fontWeight: 600 }}>
                        {scan.vehicle}
                      </p>
                      <p className="text-[#666666]" style={{ fontSize: '13px', fontWeight: 400 }}>
                        {scan.date}
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      <span
                        className={`px-3 py-1 rounded ${
                          scan.status === "safe"
                            ? "bg-[#E8F5F0] text-[#2D9970]"
                            : scan.status === "caution"
                            ? "bg-[#FEF3E2] text-[#D97706]"
                            : "bg-[#FEE8EA] text-[#C82333]"
                        }`}
                        style={{ fontSize: '13px', fontWeight: 600 }}
                      >
                        {scan.status === "safe"
                          ? "Safe"
                          : scan.status === "caution"
                          ? "Caution"
                          : "Not Recommended"}
                      </span>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>
        )}

        {scanHistory.length === 0 && (
          <div className="text-center py-16">
            <p className="text-[#666666]" style={{ fontSize: '15px' }}>
              No scan history yet. Start your first check above.
            </p>
          </div>
        )}

        {/* Top-Rated OBD-II Devices */}
        <div className="mt-12">
          <h3 className="mb-4 text-[#1A1A1A]" style={{ fontSize: '17px', fontWeight: 600 }}>MintCheck-Tested Car Scanners</h3>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Device 1 */}
            <div className="bg-white border border-[#E5E5E5] rounded p-4 flex gap-3">
              <div className="w-20 h-20 bg-[#F8F8F7] rounded flex items-center justify-center overflow-hidden flex-shrink-0">
                <img 
                  src="https://images.unsplash.com/photo-1662460150087-541eed218e0b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxibHVldG9vdGglMjBzY2FubmVyJTIwZGV2aWNlfGVufDF8fHx8MTc2ODkyMjY0M3ww&ixlib=rb-4.1.0&q=80&w=1080"
                  alt="OBD Scanner"
                  className="w-full h-full object-contain opacity-90"
                />
              </div>
              <div className="flex-1 flex flex-col">
                <h4 className="mb-0.5 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  BlueDriver Pro
                </h4>
                <p className="text-[#666666] mb-3" style={{ fontSize: '13px' }}>
                  4.8 stars • 12,000+ reviews
                </p>
                <Button 
                  variant="outline" 
                  className="w-full h-9 border-[#E5E5E5] text-[#1A1A1A] hover:bg-[#F8F8F7] hover:border-[#1A1A1A] rounded mt-auto"
                  style={{ fontWeight: 600, fontSize: '14px' }}
                  onClick={() => window.open('https://amazon.com', '_blank')}
                >
                  Buy Now
                </Button>
              </div>
            </div>

            {/* Device 2 */}
            <div className="bg-white border border-[#E5E5E5] rounded p-4 flex gap-3">
              <div className="w-20 h-20 bg-[#F8F8F7] rounded flex items-center justify-center overflow-hidden flex-shrink-0">
                <img 
                  src="https://images.unsplash.com/photo-1662460150087-541eed218e0b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxibHVldG9vdGglMjBzY2FubmVyJTIwZGV2aWNlfGVufDF8fHx8MTc2ODkyMjY0M3ww&ixlib=rb-4.1.0&q=80&w=1080"
                  alt="OBD Scanner"
                  className="w-full h-full object-contain opacity-90"
                />
              </div>
              <div className="flex-1 flex flex-col">
                <h4 className="mb-0.5 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  FIXD Premium
                </h4>
                <p className="text-[#666666] mb-3" style={{ fontSize: '13px' }}>
                  4.7 stars • 9,500+ reviews
                </p>
                <Button 
                  variant="outline" 
                  className="w-full h-9 border-[#E5E5E5] text-[#1A1A1A] hover:bg-[#F8F8F7] hover:border-[#1A1A1A] rounded mt-auto"
                  style={{ fontWeight: 600, fontSize: '14px' }}
                  onClick={() => window.open('https://amazon.com', '_blank')}
                >
                  Buy Now
                </Button>
              </div>
            </div>

            {/* Device 3 */}
            <div className="bg-white border border-[#E5E5E5] rounded p-4 flex gap-3">
              <div className="w-20 h-20 bg-[#F8F8F7] rounded flex items-center justify-center overflow-hidden flex-shrink-0">
                <img 
                  src="https://images.unsplash.com/photo-1662460150087-541eed218e0b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxibHVldG9vdGglMjBzY2FubmVyJTIwZGV2aWNlfGVufDF8fHx8MTc2ODkyMjY0M3ww&ixlib=rb-4.1.0&q=80&w=1080"
                  alt="OBD Scanner"
                  className="w-full h-full object-contain opacity-90"
                />
              </div>
              <div className="flex-1 flex flex-col">
                <h4 className="mb-0.5 text-[#1A1A1A]" style={{ fontSize: '15px', fontWeight: 600 }}>
                  Vgate iCar
                </h4>
                <p className="text-[#666666] mb-3" style={{ fontSize: '13px' }}>
                  4.6 stars • 7,200+ reviews
                </p>
                <Button 
                  variant="outline" 
                  className="w-full h-9 border-[#E5E5E5] text-[#1A1A1A] hover:bg-[#F8F8F7] hover:border-[#1A1A1A] rounded mt-auto"
                  style={{ fontWeight: 600, fontSize: '14px' }}
                  onClick={() => window.open('https://amazon.com', '_blank')}
                >
                  Buy Now
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
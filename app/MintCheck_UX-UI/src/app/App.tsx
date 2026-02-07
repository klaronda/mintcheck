import { useState } from "react";
import { HomeScreen } from "@/app/components/home-screen";
import { SignInScreen } from "@/app/components/sign-in-screen";
import { OnboardingScreen } from "@/app/components/onboarding-screen";
import { DashboardScreen } from "@/app/components/dashboard-screen";
import { VehicleBasicsScreen } from "@/app/components/vehicle-basics-screen";
import { DeviceConnectionScreen } from "@/app/components/device-connection-screen";
import { ScanningScreen } from "@/app/components/scanning-screen";
import { DisconnectReconnectScreen } from "@/app/components/disconnect-reconnect-screen";
import { VINHandlingScreen } from "@/app/components/vin-handling-screen";
import { QuickHumanCheckScreen } from "@/app/components/quick-human-check-screen";
import { ResultsScreen } from "@/app/components/results-screen";
import { SystemDetailScreen } from "@/app/components/system-detail-screen";

type Screen =
  | "home"
  | "sign-in"
  | "onboarding"
  | "dashboard"
  | "vehicle-basics"
  | "device-connection"
  | "scanning"
  | "disconnect-reconnect"
  | "vin-handling"
  | "quick-human-check"
  | "results"
  | "system-detail";

interface ScanData {
  vehicleInfo: { make: string; model: string; year: string };
  deviceType: "wifi" | "bluetooth" | null;
  vin: string | null;
  humanCheck: {
    interiorCondition: string;
    tireCondition: string;
    dashboardLights: boolean;
    engineSounds: boolean;
  } | null;
  recommendation: "safe" | "caution" | "not-recommended";
}

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>("home");
  const [user, setUser] = useState<{ email: string; firstName: string; lastName: string } | null>(null);
  const [hasSeenOnboarding, setHasSeenOnboarding] = useState(false);
  const [currentScanData, setCurrentScanData] = useState<Partial<ScanData>>({});
  const [selectedSystemDetail, setSelectedSystemDetail] = useState<string | null>(null);
  const [showSignUp, setShowSignUp] = useState(false);

  // Mock scan history
  const [scanHistory] = useState([
    {
      id: "1",
      date: "January 15, 2026",
      vehicle: "2018 Honda Accord",
      status: "safe" as const,
    },
    {
      id: "2",
      date: "January 10, 2026",
      vehicle: "2015 Toyota Camry",
      status: "caution" as const,
    },
  ]);

  const handleStartCheck = () => {
    if (!user) {
      setShowSignUp(false); // Show sign in page
      setCurrentScreen("sign-in");
    } else if (!hasSeenOnboarding) {
      setCurrentScreen("onboarding");
    } else {
      setCurrentScreen("vehicle-basics");
    }
  };

  const handleSignIn = (data: { email: string; firstName: string; lastName: string; birthdate: string }) => {
    setUser({ email: data.email, firstName: data.firstName, lastName: data.lastName });
    if (!hasSeenOnboarding) {
      setCurrentScreen("onboarding");
    } else {
      setCurrentScreen("dashboard");
    }
  };

  const handleOnboardingComplete = () => {
    setHasSeenOnboarding(true);
    if (user) {
      setCurrentScreen("dashboard");
    } else {
      setCurrentScreen("sign-in");
    }
  };

  const handleVehicleBasicsNext = (data: { make: string; model: string; year: string; vin?: string }) => {
    setCurrentScanData({ 
      ...currentScanData, 
      vehicleInfo: { make: data.make, model: data.model, year: data.year },
      vin: data.vin || null
    });
    setCurrentScreen("device-connection");
  };

  const handleDeviceConnect = (deviceType: "wifi" | "bluetooth") => {
    setCurrentScanData({ ...currentScanData, deviceType });
    setCurrentScreen("scanning");
  };

  const handleScanComplete = () => {
    setCurrentScreen("disconnect-reconnect");
  };

  const handleDisconnectComplete = () => {
    setCurrentScreen("quick-human-check");
  };

  const handleVINNext = (vin: string | null) => {
    setCurrentScanData({ ...currentScanData, vin });
    setCurrentScreen("quick-human-check");
  };

  const handleQuickCheckComplete = (data: {
    interiorCondition: string;
    tireCondition: string;
    dashboardLights: boolean;
    engineSounds: boolean;
  }) => {
    // Determine recommendation based on inputs (mock logic)
    let recommendation: "safe" | "caution" | "not-recommended" = "safe";
    
    if (data.dashboardLights || !data.engineSounds) {
      recommendation = "caution";
    }
    if (data.dashboardLights && !data.engineSounds) {
      recommendation = "not-recommended";
    }
    
    setCurrentScanData({
      ...currentScanData,
      humanCheck: data,
      recommendation,
    });
    setCurrentScreen("results");
  };

  const handleViewSystemDetail = (section: string) => {
    setSelectedSystemDetail(section);
    setCurrentScreen("system-detail");
  };

  const handleReturnToDashboard = () => {
    setCurrentScanData({});
    setCurrentScreen("dashboard");
  };

  const handleShare = () => {
    alert("Share functionality would generate a PDF or shareable link here.");
  };

  const handleViewHistory = (id: string) => {
    // In a real app, this would load the historical scan data
    alert(`Viewing scan history for scan ID: ${id}`);
  };

  // Render current screen
  return (
    <div className="size-full">
      {currentScreen === "home" && (
        <HomeScreen 
          onStartCheck={handleStartCheck} 
          onSignIn={() => {
            setShowSignUp(true); // Show create account page
            setCurrentScreen("sign-in");
          }} 
        />
      )}

      {currentScreen === "sign-in" && (
        <SignInScreen
          onBack={() => setCurrentScreen("home")}
          onSignIn={handleSignIn}
          onCreateAccount={() => setShowSignUp(true)}
          startWithSignUp={showSignUp}
        />
      )}

      {currentScreen === "onboarding" && <OnboardingScreen onComplete={handleOnboardingComplete} onBack={() => setCurrentScreen("home")} />}
      
      {currentScreen === "dashboard" && user && (
        <DashboardScreen
          onStartCheck={handleStartCheck}
          userName={user.firstName}
          scanHistory={scanHistory}
          onViewHistory={handleViewHistory}
        />
      )}

      {currentScreen === "vehicle-basics" && (
        <VehicleBasicsScreen onBack={() => setCurrentScreen("dashboard")} onNext={handleVehicleBasicsNext} />
      )}

      {currentScreen === "device-connection" && (
        <DeviceConnectionScreen onBack={() => setCurrentScreen("vehicle-basics")} onConnect={handleDeviceConnect} />
      )}

      {currentScreen === "scanning" && <ScanningScreen onComplete={handleScanComplete} />}

      {currentScreen === "disconnect-reconnect" && (
        <DisconnectReconnectScreen onComplete={handleDisconnectComplete} />
      )}

      {currentScreen === "vin-handling" && currentScanData.vehicleInfo && (
        <VINHandlingScreen
          onNext={handleVINNext}
          detectedVIN="1HGBH41JXMN109186"
          vehicleInfo={currentScanData.vehicleInfo}
        />
      )}

      {currentScreen === "quick-human-check" && <QuickHumanCheckScreen onComplete={handleQuickCheckComplete} />}

      {currentScreen === "results" && currentScanData.vehicleInfo && currentScanData.recommendation && (
        <ResultsScreen
          vehicleInfo={currentScanData.vehicleInfo}
          recommendation={currentScanData.recommendation}
          onViewDetails={handleViewSystemDetail}
          onShare={handleShare}
          onReturnHome={handleReturnToDashboard}
        />
      )}

      {currentScreen === "system-detail" && selectedSystemDetail && (
        <SystemDetailScreen
          section={selectedSystemDetail}
          status={currentScanData.recommendation === "safe" ? "Good" : "Needs Attention"}
          onBack={() => setCurrentScreen("results")}
        />
      )}
    </div>
  );
}
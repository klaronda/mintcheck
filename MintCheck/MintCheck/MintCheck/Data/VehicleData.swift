//
//  VehicleData.swift
//  MintCheck
//
//  Comprehensive vehicle makes and models database
//  Covers major manufacturers from 1996+ (OBD-II era)
//

import Foundation

/// Comprehensive vehicle makes and models for the US market
struct VehicleData {
    
    /// All car makes available in the US (alphabetized)
    static let makes: [String] = [
        "Acura",
        "Alfa Romeo",
        "Aston Martin",
        "Audi",
        "Bentley",
        "BMW",
        "Buick",
        "Cadillac",
        "Chevrolet",
        "Chrysler",
        "Dodge",
        "Ferrari",
        "Fiat",
        "Ford",
        "Genesis",
        "GMC",
        "Honda",
        "Hyundai",
        "Infiniti",
        "Jaguar",
        "Jeep",
        "Kia",
        "Lamborghini",
        "Land Rover",
        "Lexus",
        "Lincoln",
        "Lotus",
        "Maserati",
        "Mazda",
        "McLaren",
        "Mercedes-Benz",
        "Mini",
        "Mitsubishi",
        "Nissan",
        "Polestar",
        "Porsche",
        "Ram",
        "Rivian",
        "Rolls-Royce",
        "Saab",
        "Saturn",
        "Scion",
        "Smart",
        "Subaru",
        "Suzuki",
        "Tesla",
        "Toyota",
        "Volkswagen",
        "Volvo"
    ]
    
    /// Models organized by make
    static let modelsByMake: [String: [String]] = [
        "Acura": [
            "CL", "ILX", "Integra", "Legend", "MDX", "NSX", "RDX", "RL", "RLX",
            "RSX", "TL", "TLX", "TSX", "Vigor", "ZDX"
        ],
        
        "Alfa Romeo": [
            "4C", "Giulia", "Giulietta", "Stelvio", "Tonale"
        ],
        
        "Aston Martin": [
            "DB9", "DB11", "DBS", "DBX", "Rapide", "V8 Vantage", "Vanquish", "Vantage"
        ],
        
        "Audi": [
            "80", "90", "100", "200", "A3", "A4", "A5", "A6", "A7", "A8",
            "Allroad", "Cabriolet", "e-tron", "e-tron GT", "Q3", "Q4 e-tron",
            "Q5", "Q7", "Q8", "R8", "RS3", "RS4", "RS5", "RS6", "RS7",
            "RS e-tron GT", "S3", "S4", "S5", "S6", "S7", "S8", "SQ5", "SQ7",
            "SQ8", "TT", "TT RS", "TTS"
        ],
        
        "Bentley": [
            "Arnage", "Azure", "Bentayga", "Continental", "Continental GT",
            "Flying Spur", "Mulsanne"
        ],
        
        "BMW": [
            "1 Series", "2 Series", "3 Series", "4 Series", "5 Series", "6 Series",
            "7 Series", "8 Series", "i3", "i4", "i7", "i8", "iX", "M2", "M3",
            "M4", "M5", "M6", "M8", "X1", "X2", "X3", "X4", "X5", "X6", "X7",
            "XM", "Z3", "Z4", "Z8"
        ],
        
        "Buick": [
            "Cascada", "Century", "Electra", "Enclave", "Encore", "Encore GX",
            "Envision", "Envista", "LaCrosse", "LeSabre", "Lucerne", "Park Avenue",
            "Rainier", "Regal", "Rendezvous", "Riviera", "Roadmaster", "Skylark",
            "Terraza", "Verano"
        ],
        
        "Cadillac": [
            "ATS", "Brougham", "Catera", "CT4", "CT5", "CT6", "CTS", "DeVille",
            "DTS", "Eldorado", "ELR", "Escalade", "Escalade ESV", "Fleetwood",
            "Lyriq", "Seville", "SRX", "STS", "XLR", "XT4", "XT5", "XT6", "XTS"
        ],
        
        "Chevrolet": [
            "Astro", "Avalanche", "Aveo", "Beretta", "Blazer", "Bolt EUV", "Bolt EV",
            "Camaro", "Caprice", "Captiva Sport", "Cavalier", "Celebrity", "City Express",
            "Classic", "Cobalt", "Colorado", "Corsica", "Corvette", "Cruze", "El Camino",
            "Equinox", "Express", "HHR", "Impala", "Lumina", "Malibu", "Metro",
            "Monte Carlo", "Prizm", "S-10", "Silverado 1500", "Silverado 2500",
            "Silverado 3500", "Sonic", "Spark", "SS", "SSR", "Suburban", "Tahoe",
            "Tracker", "TrailBlazer", "Traverse", "Trax", "Uplander", "Venture", "Volt"
        ],
        
        "Chrysler": [
            "200", "300", "300M", "Aspen", "Cirrus", "Concorde", "Crossfire",
            "Grand Voyager", "LHS", "New Yorker", "Pacifica", "Prowler", "PT Cruiser",
            "Sebring", "Town & Country", "Voyager"
        ],
        
        "Dodge": [
            "Avenger", "Caliber", "Caravan", "Challenger", "Charger", "Dakota",
            "Dart", "Durango", "Grand Caravan", "Hornet", "Intrepid", "Journey",
            "Magnum", "Neon", "Nitro", "Ram 1500", "Ram 2500", "Ram 3500",
            "Sprinter", "Stealth", "Stratus", "Viper"
        ],
        
        "Ferrari": [
            "296 GTB", "360", "430", "458", "488", "512", "550", "575", "599",
            "612", "812", "California", "F12berlinetta", "F355", "F430", "F8",
            "FF", "GTC4Lusso", "LaFerrari", "Portofino", "Purosangue", "Roma", "SF90"
        ],
        
        "Fiat": [
            "124 Spider", "500", "500e", "500L", "500X"
        ],
        
        "Ford": [
            "Aerostar", "Aspire", "Bronco", "Bronco Sport", "C-Max", "Contour",
            "Crown Victoria", "E-150", "E-250", "E-350", "E-450", "EcoSport", "Edge",
            "Escape", "Escort", "Excursion", "Expedition", "Explorer", "Explorer Sport Trac",
            "F-150", "F-150 Lightning", "F-250", "F-350", "F-450", "Festiva", "Fiesta",
            "Five Hundred", "Flex", "Focus", "Freestar", "Freestyle", "Fusion",
            "GT", "Maverick", "Mustang", "Mustang Mach-E", "Probe", "Ranger",
            "Taurus", "Tempo", "Thunderbird", "Transit", "Transit Connect", "Windstar"
        ],
        
        "Genesis": [
            "Electrified G80", "Electrified GV70", "G70", "G80", "G90", "GV60",
            "GV70", "GV80"
        ],
        
        "GMC": [
            "Acadia", "Canyon", "Envoy", "Hummer EV", "Jimmy", "Safari", "Savana",
            "Sierra 1500", "Sierra 2500", "Sierra 3500", "Sonoma", "Terrain",
            "Yukon", "Yukon XL"
        ],
        
        "Honda": [
            "Accord", "Accord Crosstour", "Civic", "Clarity", "CR-V", "CR-Z",
            "Crosstour", "Del Sol", "Element", "Fit", "HR-V", "Insight", "Odyssey",
            "Passport", "Pilot", "Prelude", "Prologue", "Ridgeline", "S2000"
        ],
        
        "Hyundai": [
            "Accent", "Azera", "Elantra", "Entourage", "Equus", "Excel", "Genesis",
            "Genesis Coupe", "Ioniq", "Ioniq 5", "Ioniq 6", "Kona", "Kona Electric",
            "Nexo", "Palisade", "Santa Cruz", "Santa Fe", "Scoupe", "Sonata",
            "Tiburon", "Tucson", "Veloster", "Venue", "Veracruz", "XG300", "XG350"
        ],
        
        "Infiniti": [
            "EX35", "EX37", "FX35", "FX37", "FX45", "FX50", "G20", "G25", "G35",
            "G37", "I30", "I35", "J30", "JX35", "M30", "M35", "M37", "M45", "M56",
            "Q40", "Q45", "Q50", "Q60", "Q70", "QX4", "QX30", "QX50", "QX55",
            "QX56", "QX60", "QX70", "QX80"
        ],
        
        "Jaguar": [
            "E-Pace", "F-Pace", "F-Type", "I-Pace", "S-Type", "XE", "XF", "XJ",
            "XJR", "XJS", "XK", "XKR", "X-Type"
        ],
        
        "Jeep": [
            "Cherokee", "Commander", "Compass", "Gladiator", "Grand Cherokee",
            "Grand Cherokee 4xe", "Grand Cherokee L", "Grand Wagoneer", "Liberty",
            "Patriot", "Renegade", "Wagoneer", "Wrangler", "Wrangler 4xe"
        ],
        
        "Kia": [
            "Amanti", "Borrego", "Cadenza", "Carnival", "EV6", "EV9", "Forte",
            "K5", "K900", "Niro", "Niro EV", "Optima", "Rio", "Rondo", "Sedona",
            "Seltos", "Sephia", "Sorento", "Soul", "Soul EV", "Spectra", "Sportage",
            "Stinger", "Telluride"
        ],
        
        "Lamborghini": [
            "Aventador", "Countach", "Diablo", "Gallardo", "Huracan", "Murcielago",
            "Revuelto", "Urus"
        ],
        
        "Land Rover": [
            "Defender", "Discovery", "Discovery Sport", "Freelander", "LR2", "LR3",
            "LR4", "Range Rover", "Range Rover Evoque", "Range Rover Sport",
            "Range Rover Velar"
        ],
        
        "Lexus": [
            "CT 200h", "ES 250", "ES 300", "ES 300h", "ES 330", "ES 350", "GS 200t",
            "GS 300", "GS 350", "GS 400", "GS 430", "GS 450h", "GS 460", "GS F",
            "GX 460", "GX 470", "HS 250h", "IS 200t", "IS 250", "IS 300", "IS 350",
            "IS 500", "IS F", "LC 500", "LC 500h", "LFA", "LS 400", "LS 430",
            "LS 460", "LS 500", "LS 500h", "LS 600h", "LX 450", "LX 470", "LX 570",
            "LX 600", "NX 200t", "NX 250", "NX 300", "NX 300h", "NX 350", "NX 350h",
            "NX 450h+", "RC 200t", "RC 300", "RC 350", "RC F", "RX 300", "RX 330",
            "RX 350", "RX 350h", "RX 400h", "RX 450h", "RX 450h+", "RX 500h",
            "RZ 450e", "SC 300", "SC 400", "SC 430", "TX 350", "TX 500h", "TX 550h+",
            "UX 200", "UX 250h"
        ],
        
        "Lincoln": [
            "Aviator", "Blackwood", "Continental", "Corsair", "LS", "Mark LT",
            "Mark VII", "Mark VIII", "MKC", "MKS", "MKT", "MKX", "MKZ", "Nautilus",
            "Navigator", "Town Car", "Zephyr"
        ],
        
        "Lotus": [
            "Eletre", "Elise", "Emira", "Evija", "Evora", "Exige"
        ],
        
        "Maserati": [
            "Ghibli", "GranCabrio", "GranSport", "GranTurismo", "Grecale", "Levante",
            "MC20", "Quattroporte", "Spyder"
        ],
        
        "Mazda": [
            "2", "3", "5", "6", "323", "626", "929", "B-Series", "CX-3", "CX-30",
            "CX-5", "CX-50", "CX-7", "CX-9", "CX-90", "Mazda2", "Mazda3", "Mazda5",
            "Mazda6", "Millenia", "MPV", "MX-3", "MX-5 Miata", "MX-6", "MX-30",
            "Navajo", "Protege", "Protege5", "RX-7", "RX-8", "Tribute"
        ],
        
        "McLaren": [
            "540C", "570GT", "570S", "600LT", "620R", "650S", "675LT", "720S",
            "765LT", "Artura", "GT", "MP4-12C", "P1", "Senna"
        ],
        
        "Mercedes-Benz": [
            "190", "A-Class", "AMG GT", "B-Class", "C-Class", "CL-Class", "CLA-Class",
            "CLK-Class", "CLS-Class", "E-Class", "EQB", "EQC", "EQE", "EQE SUV",
            "EQS", "EQS SUV", "G-Class", "GL-Class", "GLA-Class", "GLB-Class",
            "GLC-Class", "GLE-Class", "GLK-Class", "GLS-Class", "M-Class",
            "Maybach S-Class", "Metris", "R-Class", "S-Class", "SL-Class",
            "SLC-Class", "SLK-Class", "SLR McLaren", "SLS AMG", "Sprinter"
        ],
        
        "Mini": [
            "Clubman", "Convertible", "Cooper", "Cooper Clubman", "Cooper Countryman",
            "Cooper Coupe", "Cooper Hardtop", "Cooper Paceman", "Cooper Roadster",
            "Countryman", "Hardtop", "John Cooper Works"
        ],
        
        "Mitsubishi": [
            "3000GT", "Diamante", "Eclipse", "Eclipse Cross", "Endeavor", "Galant",
            "i-MiEV", "Lancer", "Lancer Evolution", "Mirage", "Montero", "Montero Sport",
            "Outlander", "Outlander PHEV", "Outlander Sport", "Raider", "RVR"
        ],
        
        "Nissan": [
            "200SX", "240SX", "300ZX", "350Z", "370Z", "Altima", "Ariya", "Armada",
            "Cube", "Frontier", "GT-R", "Juke", "Kicks", "Leaf", "Maxima", "Murano",
            "NV200", "NV Cargo", "NV Passenger", "Pathfinder", "Quest", "Rogue",
            "Rogue Select", "Rogue Sport", "Sentra", "Stanza", "Titan", "Titan XD",
            "Versa", "Xterra", "Z"
        ],
        
        "Polestar": [
            "1", "2", "3"
        ],
        
        "Porsche": [
            "718 Boxster", "718 Cayman", "718 Spyder", "911", "918 Spyder", "928",
            "944", "968", "Boxster", "Carrera GT", "Cayenne", "Cayman", "Macan",
            "Panamera", "Taycan"
        ],
        
        "Ram": [
            "1500", "1500 Classic", "2500", "3500", "C/V", "Dakota", "ProMaster",
            "ProMaster City"
        ],
        
        "Rivian": [
            "R1S", "R1T"
        ],
        
        "Rolls-Royce": [
            "Cullinan", "Dawn", "Ghost", "Phantom", "Silver Seraph", "Spectre", "Wraith"
        ],
        
        "Saab": [
            "9-2X", "9-3", "9-4X", "9-5", "9-7X", "900", "9000"
        ],
        
        "Saturn": [
            "Astra", "Aura", "Ion", "L-Series", "LS", "LW", "Outlook", "Relay",
            "SC", "Sky", "SL", "SW", "Vue"
        ],
        
        "Scion": [
            "FR-S", "iA", "iM", "iQ", "tC", "xA", "xB", "xD"
        ],
        
        "Smart": [
            "EQ fortwo", "Fortwo"
        ],
        
        "Subaru": [
            "Ascent", "B9 Tribeca", "Baja", "BRZ", "Crosstrek", "Forester", "Impreza",
            "Impreza WRX", "Legacy", "Outback", "Solterra", "SVX", "Tribeca", "WRX",
            "XV Crosstrek"
        ],
        
        "Suzuki": [
            "Aerio", "Equator", "Esteem", "Forenza", "Grand Vitara", "Kizashi",
            "Reno", "Samurai", "Sidekick", "Swift", "SX4", "Verona", "Vitara",
            "X-90", "XL-7"
        ],
        
        "Tesla": [
            "Cybertruck", "Model 3", "Model S", "Model X", "Model Y", "Roadster"
        ],
        
        "Toyota": [
            "4Runner", "86", "Avalon", "bZ4X", "C-HR", "Camry", "Celica", "Corolla",
            "Corolla Cross", "Corolla Hatchback", "Corolla iM", "Corona", "Cressida",
            "Crown", "Echo", "FJ Cruiser", "GR Corolla", "GR Supra", "GR86",
            "Grand Highlander", "Highlander", "Land Cruiser", "Matrix", "Mirai",
            "MR2", "Paseo", "Pickup", "Previa", "Prius", "Prius c", "Prius Prime",
            "Prius v", "RAV4", "RAV4 Prime", "Sequoia", "Sienna", "Solara", "Supra",
            "T100", "Tacoma", "Tercel", "Tundra", "Venza", "Yaris", "Yaris iA"
        ],
        
        "Volkswagen": [
            "Arteon", "Atlas", "Atlas Cross Sport", "Beetle", "Cabrio", "CC",
            "Corrado", "Eos", "Eurovan", "Fox", "GLI", "Golf", "Golf Alltrack",
            "Golf GTI", "Golf R", "Golf SportWagen", "GTI", "ID.4", "ID.Buzz",
            "Jetta", "Jetta GLI", "New Beetle", "Passat", "Phaeton", "R32",
            "Rabbit", "Routan", "Taos", "Tiguan", "Tiguan Limited", "Touareg"
        ],
        
        "Volvo": [
            "240", "740", "850", "940", "960", "C30", "C40 Recharge", "C70",
            "EX30", "EX90", "S40", "S60", "S70", "S80", "S90", "V40", "V50",
            "V60", "V70", "V90", "XC40", "XC40 Recharge", "XC60", "XC70",
            "XC90"
        ]
    ]
    
    /// Get models for a specific make, returns empty array if make not found
    static func models(for make: String) -> [String] {
        return modelsByMake[make] ?? []
    }
}

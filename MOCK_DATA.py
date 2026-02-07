"""
Mock OBD-II Data for Development
Use this when no device is connected or for testing UI

Based on real scan data from 2026-01-17
"""

# Real scan from a healthy car (2026-01-17)
HEALTHY_CAR = {
    'device': 'ELM327 v1.5',
    'raw_responses': {
        'ATZ': 'ATZ\r\r\rELM327 v1.5\r\r>',
        '03': '03\r43 00 \r\r>',
        '010C': '010C\r41 0C 0E 5E \r\r>',
        '0105': '0105\r41 05 86 \r\r>',
        '010D': '010D\r41 0D 00 \r\r>',
        '0111': '0111\r41 11 29 \r\r>',
        '012F': '012F\r41 2F 71 \r\r>',
        '0142': '0142\r41 42 37 BC \r\r>',
        '010F': '010F\r41 0F 70 \r\r>',
    },
    'parsed': {
        'dtcs': [],
        'rpm': 920,
        'coolant_temp_c': 94,
        'coolant_temp_f': 201,
        'speed_kmh': 0,
        'speed_mph': 0,
        'throttle_pct': 16.1,
        'fuel_pct': 44.3,
        'battery_voltage': 14.27,
        'intake_temp_c': 72,
        'intake_temp_f': 162,
    },
    'health_score': 100,
    'summary': 'Vehicle is healthy. No issues detected.',
}

# Simulated car with minor issues
MINOR_ISSUES = {
    'device': 'ELM327 v1.5',
    'raw_responses': {
        'ATZ': 'ATZ\r\r\rELM327 v1.5\r\r>',
        '03': '03\r43 01 33 00 \r\r>',  # P0133 - O2 Sensor
        '010C': '010C\r41 0C 09 C4 \r\r>',
        '0105': '0105\r41 05 8A \r\r>',
        '010D': '010D\r41 0D 00 \r\r>',
        '0111': '0111\r41 11 25 \r\r>',
        '012F': '012F\r41 2F 4D \r\r>',
        '0142': '0142\r41 42 35 80 \r\r>',
        '010F': '010F\r41 0F 5A \r\r>',
    },
    'parsed': {
        'dtcs': ['P0133'],  # O2 Sensor Circuit Slow Response
        'rpm': 625,  # Slightly rough idle
        'coolant_temp_c': 98,
        'coolant_temp_f': 208,
        'speed_kmh': 0,
        'speed_mph': 0,
        'throttle_pct': 14.5,
        'fuel_pct': 30.2,
        'battery_voltage': 13.70,
        'intake_temp_c': 50,
        'intake_temp_f': 122,
    },
    'health_score': 75,
    'summary': 'Minor issue detected. P0133: O2 Sensor Circuit Slow Response (Bank 1 Sensor 1). This may affect fuel economy.',
}

# Simulated car with serious issues
SERIOUS_ISSUES = {
    'device': 'ELM327 v1.5',
    'raw_responses': {
        'ATZ': 'ATZ\r\r\rELM327 v1.5\r\r>',
        '03': '03\r43 03 00 01 28 02 19 \r\r>',  # P0300, P0128, P0219
        '010C': '010C\r41 0C 07 D0 \r\r>',
        '0105': '0105\r41 05 A0 \r\r>',  # Overheating!
        '010D': '010D\r41 0D 00 \r\r>',
        '0111': '0111\r41 11 35 \r\r>',
        '012F': '012F\r41 2F 28 \r\r>',
        '0142': '0142\r41 42 2E E0 \r\r>',  # Low voltage
        '010F': '010F\r41 0F 6E \r\r>',
    },
    'parsed': {
        'dtcs': ['P0300', 'P0128', 'P0219'],
        'rpm': 500,  # Very rough idle
        'coolant_temp_c': 120,  # OVERHEATING!
        'coolant_temp_f': 248,
        'speed_kmh': 0,
        'speed_mph': 0,
        'throttle_pct': 20.8,
        'fuel_pct': 15.7,
        'battery_voltage': 12.0,  # Low - alternator issue?
        'intake_temp_c': 70,
        'intake_temp_f': 158,
    },
    'health_score': 35,
    'summary': 'SERIOUS ISSUES DETECTED! Multiple trouble codes. Engine overheating (120°C). Low battery voltage may indicate alternator problem. DO NOT DRIVE - seek immediate service.',
}

# DTC Code Descriptions
DTC_DESCRIPTIONS = {
    'P0133': {
        'description': 'O2 Sensor Circuit Slow Response (Bank 1 Sensor 1)',
        'severity': 'minor',
        'symptoms': ['Reduced fuel economy', 'Slight performance loss'],
        'repair_cost_range': '$150-$300',
    },
    'P0300': {
        'description': 'Random/Multiple Cylinder Misfire Detected',
        'severity': 'serious',
        'symptoms': ['Engine shaking', 'Loss of power', 'Poor acceleration'],
        'repair_cost_range': '$100-$1000+',
    },
    'P0128': {
        'description': 'Coolant Thermostat (Coolant Temperature Below Regulating Temperature)',
        'severity': 'moderate',
        'symptoms': ['Engine runs cold', 'Poor heater performance', 'Reduced fuel economy'],
        'repair_cost_range': '$150-$400',
    },
    'P0219': {
        'description': 'Engine Overspeed Condition',
        'severity': 'serious',
        'symptoms': ['Engine damage risk', 'Rev limiter activation'],
        'repair_cost_range': 'Varies - potential engine damage',
    },
}

def get_mock_scan(scenario='healthy'):
    """Get mock scan data for development"""
    scenarios = {
        'healthy': HEALTHY_CAR,
        'minor': MINOR_ISSUES,
        'serious': SERIOUS_ISSUES,
    }
    return scenarios.get(scenario, HEALTHY_CAR)

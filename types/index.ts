export interface User {
  uid: string;
  name: string;
  email: string;
  role: 'admin' | 'user';
  farmId: string;
  createdAt: Date;
  lastLoginAt: Date;
}

export interface Farm {
  id: string;
  name: string;
  location: string;
  ownerId: string;
  cropType: string;
  status: 'active' | 'inactive';
  totalZones: number;
  createdAt: Date;
}

export interface Zone {
  id: string;
  farmId: string;
  name: string;
  cropType: string;
  targetMoisture: number;
  minimumMoisture: number;
  maximumMoisture: number;
  autoIrrigation: boolean;
  pumpStatus: 'on' | 'off';
  deviceStatus: 'online' | 'offline';
  createdAt: Date;
}

export interface SensorReading {
  id: string;
  farmId: string;
  zoneId: string;
  soilMoisture: number;
  temperature: number;
  humidity: number;
  waterLevel: number;
  flowRate: number;
  lightLevel: number;
  pumpStatus: boolean;
  deviceStatus: 'online' | 'offline';
  timestamp: Date;
}

export interface IrrigationLog {
  id: string;
  farmId: string;
  zoneId: string;
  trigger: 'automatic' | 'manual' | 'ai_recommendation' | 'emergency';
  reason: string;
  status: 'completed' | 'running' | 'failed' | 'stopped';
  durationSeconds: number;
  waterUsedLiters: number;
  startedAt: Date;
  endedAt: Date | null;
}

export interface Alert {
  id: string;
  farmId: string;
  zoneId: string;
  type: 'low_moisture' | 'high_temperature' | 'low_water' | 'pump_failure' | 'irrigation_anomaly' | 'sensor_error' | 'device_offline' | 'ai_warning';
  severity: 'critical' | 'warning' | 'info';
  title: string;
  message: string;
  resolved: boolean;
  createdAt: Date;
  resolvedAt: Date | null;
}

export interface AIAnalysis {
  id: string;
  farmId: string;
  zoneId: string;
  model: string;
  healthScore: number;
  healthStatus: 'healthy' | 'stressed' | 'critical';
  waterStress: 'low' | 'medium' | 'high';
  temperatureStatus: 'normal' | 'elevated' | 'critical';
  anomalyDetected: boolean;
  irrigationRequired: boolean;
  confidence: number;
  summary: string;
  recommendations: string[];
  createdAt: Date;
}

export interface CropProfile {
  id: string;
  name: string;
  minimumMoisture: number;
  targetMoisture: number;
  maximumMoisture: number;
  minTemperature: number;
  maxTemperature: number;
  description: string;
  createdAt: Date;
}

export interface SystemConfig {
  id: string;
  selectedModel: string;
  aiEnabled: boolean;
  temperature: number;
  maxTokens: number;
  analysisIntervalMinutes: number;
  defaultFarmId: string;
  maintenanceMode: boolean;
  updatedAt: Date;
}

export interface OpenRouterModel {
  id: string;
  name: string;
  context_length?: number;
  pricing?: {
    prompt: string;
    completion: string;
  };
  provider?: string;
}

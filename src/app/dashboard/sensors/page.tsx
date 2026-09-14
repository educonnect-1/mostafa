'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { getLatestSensorReading, getSensorHistory, subscribeToLatestReading } from '@/lib/firestore';
import type { SensorReading } from '@/types';
import { Card, CardHeader, CardTitle, CardContent, Badge, Skeleton } from '@/components/ui';
import { Droplets, Thermometer, Wind, Tank, Gauge, Sun, Wifi, WifiOff, RefreshCw } from 'lucide-react';
import { AreaChart, Area, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';

export default function SensorsPage() {
  const { userData } = useAuth();
  const [sensorReading, setSensorReading] = useState<SensorReading | null>(null);
  const [chartData, setChartData] = useState<Array<{  
    time: string; 
    moisture: number; 
    temperature: number; 
    humidity: number;
  }>>([]);
  const [loading, setLoading] = useState(true);
  const [selectedRange, setSelectedRange] = useState<'1h' | '6h' | '24h' | '7d'>('24h');

  useEffect(() => {
    async function loadSensors() {
      if (!userData?.farmId) return;

      // Get latest reading for any zone
      const reading = await getLatestSensorReading(userData.farmId);
      setSensorReading(reading);

      // Generate mock chart data based on latest reading
      if (reading) {
        const hours = selectedRange === '1h' ? 1 : selectedRange === '6h' ? 6 : selectedRange === '24h' ? 24 : 168;
        const mockData = Array.from({ length: Math.min(hours, 50) }, (_, i) => ({
          time: `${i}:00`,
          moisture: Math.min(100, Math.max(0, reading.soilMoisture + (Math.random() - 0.5) * 15)),
          temperature: Math.min(45, Math.max(10, reading.temperature + (Math.random() - 0.5) * 5)),
          humidity: Math.min(100, Math.max(20, reading.humidity + (Math.random() - 0.5) * 10)),
        }));
        setChartData(mockData);
      }

      setLoading(false);
    }

    loadSensors();
  }, [userData?.farmId, selectedRange]);

  // Subscribe to real-time updates
  useEffect(() => {
    if (!userData?.farmId) return;

    const unsubscribe = subscribeToLatestReading(userData.farmId, '', (reading) => {
      if (reading) {
        setSensorReading(reading);
      }
    });

    return () => unsubscribe();
  }, [userData?.farmId]);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <Card key={i}>
              <CardContent className="p-6">
                <Skeleton className="h-4 w-24 mb-4" />
                <Skeleton className="h-8 w-16" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-900">Sensor Readings</h2>
          <p className="text-gray-600 mt-1">Live sensor data from your IoT devices.</p>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant={sensorReading?.deviceStatus === 'online' ? 'success' : 'danger'} className="flex items-center gap-1">
            {sensorReading?.deviceStatus === 'online' ? (
              <Wifi className="h-3 w-3" />
            ) : (
              <WifiOff className="h-3 w-3" />
            )}
            {sensorReading?.deviceStatus || 'Unknown'}
          </Badge>
          <span className="text-xs text-gray-500">
            Last update: {sensorReading?.timestamp ? new Date(sensorReading.timestamp).toLocaleTimeString() : '--:--'}
          </span>
        </div>
      </div>

      {/* Sensor Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 rounded-lg">
                <Droplets className="h-5 w-5 text-blue-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Soil Moisture</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {sensorReading?.soilMoisture ?? '--'}%
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-100 rounded-lg">
                <Thermometer className="h-5 w-5 text-orange-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Temperature</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {sensorReading?.temperature.toFixed(1) ?? '--'}°C
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-cyan-100 rounded-lg">
                <Wind className="h-5 w-5 text-cyan-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Humidity</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {sensorReading?.humidity ?? '--'}%
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-100 rounded-lg">
                <Tank className="h-5 w-5 text-indigo-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Water Level</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {sensorReading?.waterLevel ?? '--'}%
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 rounded-lg">
                <Gauge className="h-5 w-5 text-emerald-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Flow Rate</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {sensorReading?.flowRate.toFixed(1) ?? '--'} L/min
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-yellow-100 rounded-lg">
                <Sun className="h-5 w-5 text-yellow-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500">Light Level</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {sensorReading?.lightLevel ?? '--'}%
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Environmental Trends</CardTitle>
              <div className="flex gap-1">
                {(['1h', '6h', '24h', '7d'] as const).map((range) => (
                  <button
                    key={range}
                    onClick={() => setSelectedRange(range)}
                    className={`px-2 py-1 text-xs rounded ${
                      selectedRange === range 
                        ? 'bg-green-600 text-white' 
                        : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                    }`}
                  >
                    {range}
                  </button>
                ))}
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {chartData.length > 0 ? (
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={chartData}>
                    <defs>
                      <linearGradient id="colorMoisture" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                        <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis dataKey="time" stroke="#9ca3af" fontSize={12} />
                    <YAxis stroke="#9ca3af" fontSize={12} />
                    <Tooltip 
                      contentStyle={{ 
                        backgroundColor: '#fff', 
                        border: '1px solid #e5e7eb',
                        borderRadius: '8px'
                      }} 
                    />
                    <Legend />
                    <Area 
                      type="monotone" 
                      dataKey="moisture" 
                      name="Moisture %"
                      stroke="#3b82f6" 
                      strokeWidth={2}
                      fill="url(#colorMoisture)" 
                    />
                    <Line 
                      type="monotone" 
                      dataKey="temperature" 
                      name="Temp °C"
                      stroke="#f97316" 
                      strokeWidth={2}
                      dot={false}
                    />
                    <Line 
                      type="monotone" 
                      dataKey="humidity" 
                      name="Humidity %"
                      stroke="#06b6d4" 
                      strokeWidth={2}
                      dot={false}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            ) : (
              <div className="h-64 flex items-center justify-center">
                <p className="text-gray-500">No historical data available</p>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Sensor Health</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <div className="flex items-center gap-3">
                <div className={`h-2 w-2 rounded-full ${sensorReading?.deviceStatus === 'online' ? 'bg-green-500' : 'bg-red-500'}`} />
                <span className="text-sm font-medium">Device Status</span>
              </div>
              <Badge variant={sensorReading?.deviceStatus === 'online' ? 'success' : 'danger'}>
                {sensorReading?.deviceStatus || 'Unknown'}
              </Badge>
            </div>

            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <div className="flex items-center gap-3">
                <div className={`h-2 w-2 rounded-full ${sensorReading?.pumpStatus ? 'bg-green-500' : 'bg-gray-400'}`} />
                <span className="text-sm font-medium">Pump Status</span>
              </div>
              <Badge variant={sensorReading?.pumpStatus ? 'success' : 'default'}>
                {sensorReading?.pumpStatus ? 'ON' : 'OFF'}
              </Badge>
            </div>

            <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex items-start gap-3">
                <RefreshCw className="h-5 w-5 text-blue-600 mt-0.5" />
                <div>
                  <p className="text-sm font-medium text-blue-900">Waiting for Sensor Data</p>
                  <p className="text-xs text-blue-700 mt-1">
                    ESP32 devices should send readings to Firestore automatically. 
                    Once connected, live data will appear here.
                  </p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

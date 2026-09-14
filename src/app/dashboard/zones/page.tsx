'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { getZones, type Zone } from '@/lib/firestore';
import { Card, CardHeader, CardTitle, CardContent, Badge, Skeleton } from '@/components/ui';
import { MapPin, Droplets, Thermometer, Power, Wifi, WifiOff, Leaf } from 'lucide-react';
import Link from 'next/link';

export default function ZonesPage() {
  const { userData } = useAuth();
  const [zones, setZones] = useState<Zone[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadZones() {
      if (!userData?.farmId) return;
      
      const fetchedZones = await getZones(userData.farmId);
      setZones(fetchedZones);
      setLoading(false);
    }

    loadZones();
  }, [userData?.farmId]);

  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {Array.from({ length: 6 }).map((_, i) => (
          <Card key={i}>
            <CardContent className="p-6">
              <Skeleton className="h-6 w-32 mb-4" />
              <Skeleton className="h-4 w-24 mb-2" />
              <Skeleton className="h-4 w-20" />
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  if (zones.length === 0) {
    return (
      <div className="text-center py-12">
        <MapPin className="h-12 w-12 text-gray-400 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-gray-900 mb-2">No zones configured</h3>
        <p className="text-gray-500">Zones will appear here once they are set up for your farm.</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold text-gray-900">Farm Zones</h2>
        <p className="text-gray-600 mt-1">Monitor and manage your irrigation zones.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {zones.map((zone) => (
          <Link href={`/dashboard/zones/${zone.id}`} key={zone.id}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div>
                    <CardTitle>{zone.name}</CardTitle>
                    <p className="text-sm text-gray-500 mt-1 capitalize">{zone.cropType}</p>
                  </div>
                  <Badge variant={zone.deviceStatus === 'online' ? 'success' : 'danger'}>
                    {zone.deviceStatus}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-500 flex items-center gap-2">
                    <Droplets className="h-4 w-4" /> Moisture
                  </span>
                  <span className="font-medium">--%</span>
                </div>
                
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-500 flex items-center gap-2">
                    <Thermometer className="h-4 w-4" /> Temperature
                  </span>
                  <span className="font-medium">--°C</span>
                </div>

                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-500 flex items-center gap-2">
                    <Power className="h-4 w-4" /> Pump
                  </span>
                  <Badge variant={zone.pumpStatus === 'on' ? 'success' : 'default'}>
                    {zone.pumpStatus.toUpperCase()}
                  </Badge>
                </div>

                <div className="pt-3 border-t border-gray-100">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-gray-500">Auto Irrigation</span>
                    <Badge variant={zone.autoIrrigation ? 'info' : 'default'}>
                      {zone.autoIrrigation ? 'Enabled' : 'Disabled'}
                    </Badge>
                  </div>
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  );
}

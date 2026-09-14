'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { getAlerts, resolveAlert } from '@/lib/firestore';
import type { Alert } from '@/types';
import { Card, CardHeader, CardTitle, CardContent, Badge, Skeleton, Button } from '@/components/ui';
import { AlertTriangle, AlertCircle, Info, CheckCircle, X, Filter } from 'lucide-react';

type SeverityFilter = 'all' | 'critical' | 'warning' | 'info' | 'resolved' | 'unresolved';

export default function AlertsPage() {
  const { userData } = useAuth();
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<SeverityFilter>('all');

  useEffect(() => {
    async function loadAlerts() {
      if (!userData?.farmId) return;
      
      const fetchedAlerts = await getAlerts(userData.farmId);
      setAlerts(fetchedAlerts);
      setLoading(false);
    }

    loadAlerts();
  }, [userData?.farmId]);

  const handleResolve = async (alertId: string) => {
    await resolveAlert(alertId);
    setAlerts(prev => prev.map(a => 
      a.id === alertId ? { ...a, resolved: true, resolvedAt: new Date() } : a
    ));
  };

  const getSeverityIcon = (severity: string) => {
    switch (severity) {
      case 'critical': return <AlertTriangle className="h-5 w-5 text-red-600" />;
      case 'warning': return <AlertCircle className="h-5 w-5 text-yellow-600" />;
      case 'info': return <Info className="h-5 w-5 text-blue-600" />;
      default: return <AlertCircle className="h-5 w-5 text-gray-600" />;
    }
  };

  const getTypeLabel = (type: string) => {
    const labels: Record<string, string> = {
      low_moisture: 'Low Soil Moisture',
      high_temperature: 'High Temperature',
      low_water: 'Low Water Level',
      pump_failure: 'Pump Failure',
      irrigation_anomaly: 'Irrigation Anomaly',
      sensor_error: 'Sensor Error',
      device_offline: 'Device Offline',
      ai_warning: 'AI Warning',
    };
    return labels[type] || type;
  };

  const filteredAlerts = alerts.filter(alert => {
    if (filter === 'all') return true;
    if (filter === 'resolved') return alert.resolved;
    if (filter === 'unresolved') return !alert.resolved;
    return alert.severity === filter;
  });

  const unresolvedCount = alerts.filter(a => !a.resolved).length;

  if (loading) {
    return (
      <div className="space-y-4">
        {Array.from({ length: 5 }).map((_, i) => (
          <Card key={i}>
            <CardContent className="p-4">
              <Skeleton className="h-16 w-full" />
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-900">System Alerts</h2>
          <p className="text-gray-600 mt-1">
            {unresolvedCount > 0 
              ? `${unresolvedCount} unresolved alert${unresolvedCount !== 1 ? 's' : ''}`
              : 'All alerts resolved'
            }
          </p>
        </div>
        
        <div className="flex items-center gap-2">
          <Filter className="h-4 w-4 text-gray-500" />
          <select
            value={filter}
            onChange={(e) => setFilter(e.target.value as SeverityFilter)}
            className="text-sm border border-gray-300 rounded-lg px-3 py-1.5 bg-white focus:ring-2 focus:ring-green-500"
          >
            <option value="all">All Alerts</option>
            <option value="critical">Critical</option>
            <option value="warning">Warning</option>
            <option value="info">Info</option>
            <option value="unresolved">Unresolved</option>
            <option value="resolved">Resolved</option>
          </select>
        </div>
      </div>

      {filteredAlerts.length > 0 ? (
        <div className="space-y-3">
          {filteredAlerts.map((alert) => (
            <Card 
              key={alert.id} 
              className={`border-l-4 ${
                alert.severity === 'critical' ? 'border-l-red-500' :
                alert.severity === 'warning' ? 'border-l-yellow-500' : 'border-l-blue-500'
              } ${alert.resolved ? 'opacity-60' : ''}`}
            >
              <CardContent className="p-4">
                <div className="flex items-start gap-4">
                  <div className="flex-shrink-0">
                    {getSeverityIcon(alert.severity)}
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h4 className="text-sm font-semibold text-gray-900">{getTypeLabel(alert.type)}</h4>
                      <Badge variant={
                        alert.severity === 'critical' ? 'danger' :
                        alert.severity === 'warning' ? 'warning' : 'info'
                      }>
                        {alert.severity}
                      </Badge>
                      {alert.resolved && (
                        <Badge variant="success" className="flex items-center gap-1">
                          <CheckCircle className="h-3 w-3" />
                          Resolved
                        </Badge>
                      )}
                    </div>
                    
                    <p className="text-sm text-gray-600 mb-2">{alert.message}</p>
                    
                    <div className="flex items-center gap-4 text-xs text-gray-500">
                      <span>Created: {alert.createdAt ? new Date(alert.createdAt).toLocaleString() : '--'}</span>
                      {alert.resolvedAt && (
                        <span>Resolved: {new Date(alert.resolvedAt).toLocaleString()}</span>
                      )}
                    </div>
                  </div>

                  {!alert.resolved && (
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleResolve(alert.id)}
                      className="flex-shrink-0"
                    >
                      <CheckCircle className="h-4 w-4 mr-1" />
                      Resolve
                    </Button>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <Card>
          <CardContent className="p-12 text-center">
            <CheckCircle className="h-16 w-16 text-green-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              {filter === 'resolved' || filter === 'all' ? 'No alerts' : `No ${filter} alerts`}
            </h3>
            <p className="text-gray-500">
              {filter === 'resolved' || filter === 'all' 
                ? "Your farm is running smoothly. You'll see alerts here if any issues arise."
                : `There are no ${filter} alerts at this time.`
              }
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

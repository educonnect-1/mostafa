'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { getIrrigationLogs } from '@/lib/firestore';
import type { IrrigationLog } from '@/types';
import { Card, CardHeader, CardTitle, CardContent, Badge, Skeleton } from '@/components/ui';
import { Droplets, Clock, Calendar, CheckCircle, XCircle, AlertCircle, Play, Square } from 'lucide-react';

export default function IrrigationPage() {
  const { userData } = useAuth();
  const [logs, setLogs] = useState<IrrigationLog[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadLogs() {
      if (!userData?.farmId) return;
      
      const fetchedLogs = await getIrrigationLogs(userData.farmId);
      setLogs(fetchedLogs);
      setLoading(false);
    }

    loadLogs();
  }, [userData?.farmId]);

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}m ${secs}s`;
  };

  const getTriggerBadge = (trigger: string) => {
    switch (trigger) {
      case 'automatic': return <Badge variant="info">Automatic</Badge>;
      case 'manual': return <Badge variant="default">Manual</Badge>;
      case 'ai_recommendation': return <Badge variant="success">AI</Badge>;
      case 'emergency': return <Badge variant="danger">Emergency</Badge>;
      default: return <Badge>{trigger}</Badge>;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed': return <CheckCircle className="h-4 w-4 text-green-600" />;
      case 'running': return <Play className="h-4 w-4 text-blue-600 animate-pulse" />;
      case 'failed': return <XCircle className="h-4 w-4 text-red-600" />;
      case 'stopped': return <Square className="h-4 w-4 text-gray-600" />;
      default: return <AlertCircle className="h-4 w-4 text-gray-600" />;
    }
  };

  const totalWaterUsed = logs.reduce((sum, log) => sum + (log.waterUsedLiters || 0), 0);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <Card key={i}>
              <CardContent className="p-6">
                <Skeleton className="h-4 w-24 mb-4" />
                <Skeleton className="h-8 w-32" />
              </CardContent>
            </Card>
          ))}
        </div>
        <Card>
          <CardContent className="p-6">
            <Skeleton className="h-64 w-full" />
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold text-gray-900">Irrigation Control</h2>
        <p className="text-gray-600 mt-1">Monitor and manage irrigation cycles.</p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-blue-100 rounded-lg">
                <Droplets className="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Total Water Used</p>
                <p className="text-2xl font-semibold text-gray-900">{totalWaterUsed.toFixed(1)} L</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-green-100 rounded-lg">
                <CheckCircle className="h-6 w-6 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Completed Cycles</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {logs.filter(l => l.status === 'completed').length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-purple-100 rounded-lg">
                <Clock className="h-6 w-6 text-purple-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Avg Duration</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {logs.length > 0 
                    ? formatDuration(Math.round(logs.reduce((sum, l) => sum + (l.durationSeconds || 0), 0) / logs.length))
                    : '--'
                  }
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Irrigation Timeline */}
      <Card>
        <CardHeader>
          <CardTitle>Irrigation History</CardTitle>
        </CardHeader>
        <CardContent>
          {logs.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200">
                    <th className="text-left py-3 px-4 text-xs font-medium text-gray-500 uppercase">Status</th>
                    <th className="text-left py-3 px-4 text-xs font-medium text-gray-500 uppercase">Trigger</th>
                    <th className="text-left py-3 px-4 text-xs font-medium text-gray-500 uppercase">Reason</th>
                    <th className="text-left py-3 px-4 text-xs font-medium text-gray-500 uppercase">Duration</th>
                    <th className="text-left py-3 px-4 text-xs font-medium text-gray-500 uppercase">Water Used</th>
                    <th className="text-left py-3 px-4 text-xs font-medium text-gray-500 uppercase">Started</th>
                  </tr>
                </thead>
                <tbody>
                  {logs.map((log) => (
                    <tr key={log.id} className="border-b border-gray-100 hover:bg-gray-50">
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-2">
                          {getStatusIcon(log.status)}
                          <span className="text-sm capitalize">{log.status}</span>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        {getTriggerBadge(log.trigger)}
                      </td>
                      <td className="py-3 px-4 text-sm text-gray-600 max-w-xs truncate">
                        {log.reason}
                      </td>
                      <td className="py-3 px-4 text-sm text-gray-600">
                        {formatDuration(log.durationSeconds || 0)}
                      </td>
                      <td className="py-3 px-4 text-sm text-gray-600">
                        {log.waterUsedLiters?.toFixed(1) || 0} L
                      </td>
                      <td className="py-3 px-4 text-sm text-gray-600">
                        {log.startedAt ? new Date(log.startedAt).toLocaleString() : '--'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="text-center py-12">
              <Droplets className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No irrigation events</h3>
              <p className="text-gray-500">Irrigation logs will appear here once irrigation cycles are recorded.</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Manual Control Notice */}
      <Card className="border-yellow-200 bg-yellow-50">
        <CardContent className="p-4">
          <div className="flex items-start gap-3">
            <AlertCircle className="h-5 w-5 text-yellow-600 mt-0.5" />
            <div>
              <p className="text-sm font-medium text-yellow-900">Manual Irrigation Control</p>
              <p className="text-xs text-yellow-700 mt-1">
                Manual pump control requires hardware integration. The AI system provides recommendations only - 
                physical pump control is handled by the deterministic irrigation layer based on safety checks.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

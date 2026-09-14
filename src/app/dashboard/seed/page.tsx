'use client';

import { useState } from 'react';
import { Button, Card, CardHeader, CardTitle, CardContent } from '@/components/ui';
import { seedDemoData } from '@/services/seedService';
import { Database, CheckCircle, Loader2, AlertCircle } from 'lucide-react';

export default function SeedPage() {
  const [seeding, setSeeding] = useState(false);
  const [result, setResult] = useState<{ success: boolean; message: string } | null>(null);

  const handleSeed = async () => {
    setSeeding(true);
    setResult(null);
    
    try {
      await seedDemoData();
      setResult({ success: true, message: 'Demo data seeded successfully! Refresh the dashboard to see the data.' });
    } catch (error) {
      setResult({ 
        success: false, 
        message: error instanceof Error ? error.message : 'Failed to seed data' 
      });
    } finally {
      setSeeding(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="p-2 bg-green-100 rounded-lg">
              <Database className="h-6 w-6 text-green-600" />
            </div>
            <div>
              <CardTitle>Demo Data Seeder</CardTitle>
              <p className="text-sm text-gray-500 mt-1">AgriGuard AI</p>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <div className="flex items-start gap-3">
              <AlertCircle className="h-5 w-5 text-yellow-600 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-yellow-900">Important</p>
                <p className="text-xs text-yellow-700 mt-1">
                  This will create demo data in your Firebase Firestore database. Make sure you have configured your Firebase credentials first.
                </p>
              </div>
            </div>
          </div>

          <p className="text-sm text-gray-600">
            This utility creates realistic demo data for testing the dashboard:
          </p>
          <ul className="text-sm text-gray-600 space-y-1 ml-4 list-disc">
            <li>Demo farm and zones</li>
            <li>48 hours of sensor readings</li>
            <li>AI analysis records</li>
            <li>Irrigation logs</li>
            <li>Sample alerts</li>
            <li>Crop profiles</li>
            <li>System configuration</li>
          </ul>

          {result && (
            <div className={`p-4 rounded-lg flex items-center gap-3 ${
              result.success ? 'bg-green-50' : 'bg-red-50'
            }`}>
              <CheckCircle className={`h-5 w-5 ${
                result.success ? 'text-green-600' : 'text-red-600'
              }`} />
              <p className={`text-sm ${
                result.success ? 'text-green-800' : 'text-red-800'
              }`}>{result.message}</p>
            </div>
          )}

          <Button 
            onClick={handleSeed} 
            disabled={seeding}
            className="w-full"
          >
            {seeding ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Seeding...
              </>
            ) : (
              <>
                <Database className="h-4 w-4 mr-2" />
                Generate Demo Data
              </>
            )}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}

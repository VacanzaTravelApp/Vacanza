import React from 'react';
import { Skeleton, Card, Divider } from 'antd';

const GamificationSkeleton = () => {
  return (
    <div className="gamification-page">
      <Card className="gamification-card">
        {/* Header Skeleton */}
        <div className="gamification-header" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <Skeleton.Avatar active size={80} shape="circle" style={{ marginBottom: 16 }} />
          <Skeleton.Input active size="small" style={{ width: 150, marginBottom: 8 }} />
          <Skeleton.Input active size="default" style={{ width: 100 }} />
        </div>

        {/* Stats Skeleton */}
        <div className="stats-row" style={{ marginTop: 32, justifyContent: 'space-around' }}>
          <Skeleton.Button active style={{ width: 60 }} />
          <Divider type="vertical" style={{ height: 24 }} />
          <Skeleton.Button active style={{ width: 60 }} />
          <Divider type="vertical" style={{ height: 24 }} />
          <Skeleton.Button active style={{ width: 60 }} />
        </div>

        {/* Progress Skeleton */}
        <div className="xp-section" style={{ marginTop: 32 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
            <Skeleton.Input active size="small" style={{ width: 50 }} />
            <Skeleton.Input active size="small" style={{ width: 50 }} />
          </div>
          <Skeleton active paragraph={{ rows: 0 }} />
        </div>

        {/* Badges Skeleton */}
        <div className="badges-section" style={{ marginTop: 32 }}>
          <Skeleton.Input active size="small" style={{ width: 100, marginBottom: 16 }} />
          <div style={{ display: 'flex', gap: 16 }}>
            <Skeleton.Avatar active size={50} shape="square" />
            <Skeleton.Avatar active size={50} shape="square" />
            <Skeleton.Avatar active size={50} shape="square" />
          </div>
        </div>
      </Card>
    </div>
  );
};

export default GamificationSkeleton;
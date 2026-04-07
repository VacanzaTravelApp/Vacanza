import React from 'react';
import { Button, Result } from 'antd';

const GamificationErrorState = ({ onRetry }) => {
  return (
    <div className="gamification-page">
      <Result
        status="error"
        title="Data Cannot Be Loaded"
        subTitle="Your profile information is currently unavailable. Please check your connection and try again."
        extra={[
          <Button type="primary" key="retry" onClick={onRetry}>
            Try Again
          </Button>
        ]}
      />
    </div>
  );
};

export default GamificationErrorState;
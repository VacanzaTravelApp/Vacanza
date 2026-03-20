import React from 'react';
import { Button, Result } from 'antd';

const GamificationErrorState = ({ onRetry }) => {
  return (
    <div className="gamification-page">
      <Result
        status="error"
        title="Veriler Yüklenemedi"
        subTitle="Profil bilgilerine şu an ulaşılamıyor. Lütfen internet bağlantınızı kontrol edip tekrar deneyin."
        extra={[
          <Button type="primary" key="retry" onClick={onRetry}>
            Yeniden Dene
          </Button>
        ]}
      />
    </div>
  );
};

export default GamificationErrorState;
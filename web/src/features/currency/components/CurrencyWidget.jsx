import React, { useState, useEffect } from 'react';
import { Card, InputNumber, Select, Button, message, Spin, Space, Divider, Typography, Alert } from 'antd';
import { SwapOutlined, DollarOutlined, LineChartOutlined, CloseOutlined } from '@ant-design/icons';
import { currencyApi } from '../../../api/currencyApi';

const { Title, Text } = Typography;
const { Option } = Select;

const MAJOR_CURRENCIES = [
    'USD', 'EUR', 'GBP', 'TRY', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'HKD', 'NZD', 'SEK', 'KRW', 'SGD', 'NOK', 'MXN', 'INR', 'RUB', 'BRL', 'ZAR'
];

export default function CurrencyWidget({ onClose }) {
    const [conversion, setConversion] = useState({
        amount: 1,
        from: 'USD',
        to: 'TRY',
        result: null
    });
    const [loading, setLoading] = useState(false);
    const [errorStatus, setErrorStatus] = useState(null);

    const handleConvert = async () => {
        if (!conversion.amount) return;
        setLoading(true);
        setErrorStatus(null);
        try {
            const data = await currencyApi.convert(conversion.amount, conversion.from, conversion.to);
            setConversion(prev => ({ ...prev, result: data.convertedAmount }));
        } catch (err) {
            if (err.response?.status === 503) {
                setErrorStatus(503);
            } else {
                message.error("Currency conversion failed. Please try again.");
            }
        } finally {
            setLoading(false);
        }
    };

    const swapCurrencies = () => {
        setConversion(prev => ({
            ...prev,
            from: prev.to,
            to: prev.from,
            result: null
        }));
    };

    useEffect(() => {
        handleConvert();
    }, [conversion.from, conversion.to]);

    return (
        <div className="glass-panel currency-panel currency-panel-refined">
            <div className="currency-panel-header">
                <Title level={5} className="currency-panel-title">
                    <DollarOutlined className="currency-icon-vivid" /> Currency Converter
                </Title>
                <Button type="text" icon={<CloseOutlined />} onClick={onClose} size="small" />
            </div>

            {errorStatus === 503 && (
                <Alert
                    message="Service Interruption"
                    description="Currency conversion is temporarily unavailable, prices are shown in original currency."
                    type="warning"
                    showIcon
                    style={{ marginBottom: 16, fontSize: '11px', borderRadius: '12px' }}
                />
            )}

            <Space direction="vertical" style={{ width: '100%' }} size="middle">
                <div>
                    <Text className="currency-label-tiny">Amount</Text>
                    <InputNumber
                        min={0}
                        className="currency-input-glass"
                        value={conversion.amount}
                        onChange={val => setConversion(prev => ({ ...prev, amount: val, result: null }))}
                        onPressEnter={handleConvert}
                        prefix={<DollarOutlined />}
                        size="large"
                    />
                </div>

                <div className="currency-controls-row">
                    <div style={{ flex: 1 }}>
                        <Text className="currency-label-tiny">From</Text>
                        <Select
                            showSearch
                            className="currency-select-glass"
                            value={conversion.from}
                            onChange={val => setConversion(prev => ({ ...prev, from: val }))}
                            size="large"
                        >
                            {MAJOR_CURRENCIES.map(c => <Option key={c} value={c}>{c}</Option>)}
                        </Select>
                    </div>

                    <Button
                        shape="circle"
                        icon={<SwapOutlined />}
                        onClick={swapCurrencies}
                        className="currency-swap-trigger"
                    />

                    <div style={{ flex: 1 }}>
                        <Text className="currency-label-tiny">To</Text>
                        <Select
                            showSearch
                            className="currency-select-glass"
                            value={conversion.to}
                            onChange={val => setConversion(prev => ({ ...prev, to: val }))}
                            size="large"
                        >
                            {MAJOR_CURRENCIES.map(c => <Option key={c} value={c}>{c}</Option>)}
                        </Select>
                    </div>
                </div>

                <Button
                    type="primary"
                    block
                    className="currency-action-btn"
                    onClick={handleConvert}
                    loading={loading}
                    size="large"
                >
                    Convert Now
                </Button>

                {conversion.result !== null && (
                    <div className="currency-result-display">
                        <Text className="currency-result-pre">{conversion.amount} {conversion.from} =</Text>
                        <Title level={2} className="currency-result-main">
                            {conversion.result.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} {conversion.to}
                        </Title>
                    </div>
                )}
            </Space>

            <div className="currency-panel-footer">
                <Text type="secondary" style={{ fontSize: 10, opacity: 0.6 }}>
                    <LineChartOutlined /> Real-time rates powered by Frankfurter API
                </Text>
            </div>
        </div>
    );
}


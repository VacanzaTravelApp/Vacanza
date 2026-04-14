import React, { useState, useEffect, useMemo } from "react";
import { Modal, Form, InputNumber, Select, Row, Col, Typography, Button, message, Input, ConfigProvider } from "antd";
import {
    CloseOutlined,
    ThunderboltOutlined,
    RightOutlined,
    DownOutlined,
    UpOutlined,
    ArrowLeftOutlined,
    SearchOutlined
} from "@ant-design/icons";
import { useQueryClient, useMutation } from "@tanstack/react-query";
import { useUserPreferences } from "../hooks/useUserPreferences";
import { userApi } from "../api/userApi";
import dayjs from "dayjs";

const { Title } = Typography;

function formatLabel(str) {
    if (!str) return "";
    return str.replace(/_/g, " ").replace(/\w\S*/g, (txt) => txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase());
}

const GrabHandle = () => (
    <div style={{ display: "flex", justifyContent: "center", padding: "12px 0 16px" }}>
        <div style={{ width: 40, height: 4, background: "var(--card-border, rgba(0,0,0,0.1))", borderRadius: 2 }} />
    </div>
);

const CustomCheckbox = ({ checked, themeColor }) => (
    <div style={{
        width: 20, height: 20, borderRadius: 6,
        border: checked ? `none` : "2px solid var(--card-border, rgba(0,0,0,0.1))",
        background: checked ? themeColor : "transparent",
        display: "flex", alignItems: "center", justifyContent: "center",
        transition: "all 0.2s ease",
        flexShrink: 0
    }}>
        {checked && (
            <svg width="10" height="10" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M13.3333 4L5.99996 11.3333L2.66663 8" stroke="white" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
        )}
    </div>
);

const ChipSelector = ({ options, value, onChange, color = "var(--theme-primary)", isMulti = false, maxVisible = 100, onToggleMore, isExpanded, circle = false }) => {
    const valuesStr = isMulti ? (Array.isArray(value) ? value : []).map(v => String(v).toUpperCase()) : [];
    const valStr = value ? String(value).toUpperCase() : "";
    const visibleOptions = isExpanded ? options : options.slice(0, maxVisible);
    const hasMore = options.length > maxVisible;

    const handleToggle = (opt) => {
        const uOpt = String(opt).toUpperCase();
        if (isMulti) {
            const currentVals = Array.isArray(value) ? value : [];
            const newVals = valuesStr.includes(uOpt)
                ? currentVals.filter(v => String(v).toUpperCase() !== uOpt)
                : [...currentVals, opt];
            onChange(newVals);
        } else {
            onChange(opt);
        }
    };

    return (
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginBottom: 10 }}>
            {visibleOptions.map(opt => {
                const uOpt = String(opt).toUpperCase();
                const isSelected = isMulti ? valuesStr.includes(uOpt) : valStr === uOpt;
                return (
                    <div
                        key={opt}
                        onClick={() => handleToggle(opt)}
                        style={{
                            padding: circle ? "0" : "10px 18px",
                            width: circle ? 42 : "auto",
                            height: circle ? 42 : "auto",
                            borderRadius: circle ? "50%" : 14,
                            fontSize: 14, fontWeight: 700,
                            cursor: "pointer", transition: "all 0.2s cubic-bezier(0.4, 0, 0.2, 1)",
                            background: isSelected ? color : "var(--vivid-subtle-bg, rgba(0,0,0,0.05))",
                            color: isSelected ? "#fff" : "var(--text-main, rgba(0,0,0,0.4))",
                            display: "flex", alignItems: "center", justifyContent: "center",
                            border: isSelected ? `1px solid ${color}` : "1px solid var(--card-border, rgba(0,0,0,0.02))",
                        }}
                    >
                        {formatLabel(opt)}
                    </div>
                );
            })}
            {hasMore && (
                <div
                    onClick={onToggleMore}
                    style={{ padding: "8px 16px", borderRadius: 12, fontSize: 13, fontWeight: 700, background: "var(--vivid-subtle-bg, rgba(0,0,0,0.05))", color: "var(--theme-primary)", cursor: "pointer", display: "flex", alignItems: "center", gap: 4 }}
                >
                    {isExpanded ? "Less" : "More..."}
                </div>
            )}
        </div>
    );
};

const SegmentedControl = ({ value, onChange, options, isDarkMode = true }) => (
    <div style={{
        display: "flex", background: "var(--vivid-subtle-bg, rgba(255,255,255,0.05))", borderRadius: 14,
        padding: 4, gap: 4, marginBottom: 4,
        border: "1px solid var(--card-border, transparent)"
    }}>
        {options.map(opt => {
            const isSelected = value && String(value).toUpperCase() === String(opt).toUpperCase();
            return (
                <div
                    key={opt}
                    onClick={() => onChange(opt)}
                    style={{
                        flex: 1, textAlign: "center", padding: "10px 0",
                        borderRadius: 11, cursor: "pointer", transition: "all 0.2s ease",
                        background: isSelected ? "var(--theme-primary)" : "transparent",
                        color: isSelected ? "#fff" : "var(--text-sub, rgba(255,255,255,0.4))",
                        fontWeight: 700, fontSize: 14,
                    }}
                >
                    {formatLabel(opt)}
                </div>
            );
        })}
    </div>
);

const CurrencySelector = ({ value, onChange, isDarkMode = true }) => (
    <ConfigProvider
        theme={{
            token: {
                colorBgContainer: isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)',
                colorText: isDarkMode ? '#FFFFFF' : '#1A2333',
                colorTextPlaceholder: isDarkMode ? 'rgba(255,255,255,0.55)' : 'rgba(0,0,0,0.4)',
                colorBorder: 'transparent',
                colorPrimary: isDarkMode ? '#38BDF8' : '#FF6B6B',
                colorBgElevated: isDarkMode ? '#1A2333' : '#FFFFFF',
                colorIcon: isDarkMode ? 'rgba(255,255,255,0.4)' : 'rgba(0,0,0,0.4)',
            }
        }}
    >
        <Select
            value={value}
            onChange={onChange}
            variant="borderless"
            placeholder="Cur"
            style={{ width: '100%', height: 48, background: isDarkMode ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.05)", borderRadius: 12, fontSize: 15, fontWeight: 800, color: isDarkMode ? "#FFFFFF" : "#1A2333" }}
            getPopupContainer={(trigger) => trigger.parentNode}
            options={["EUR", "USD", "GBP", "TRY"].map(c => ({ label: c, value: c }))}
        />
    </ConfigProvider>
);

const FieldLabel = ({ text, subtext, color = "var(--text-sub, rgba(255,255,255,0.4))" }) => (
    <div style={{ marginBottom: 12, marginTop: 24 }}>
        <div style={{ fontSize: 12, fontWeight: 900, color: color, letterSpacing: "1.5px" }}>{text.toUpperCase()}</div>
        {subtext && <div style={{ fontSize: 12, color: "var(--theme-primary)", marginTop: 6, display: "flex", alignItems: "center", gap: 4, fontWeight: 700 }}>
            <ThunderboltOutlined style={{ fontSize: 11 }} /> {subtext}
        </div>}
    </div>
);

const MultiSelectRow = ({ label, values, color, onClick }) => {
    const summary = !values || values.length === 0
        ? "None selected" : values.length <= 2
            ? values.map(v => formatLabel(v)).join(", ")
            : `${values.slice(0, 2).map(v => formatLabel(v)).join(", ")} +${values.length - 2}`;

    return (
        <div
            onClick={onClick}
            style={{
                background: "var(--vivid-subtle-bg, rgba(255,255,255,0.05))", borderRadius: 16, padding: "14px 18px",
                display: "flex", alignItems: "center", cursor: "pointer",
                border: "1px solid var(--card-border, rgba(255,255,255,0.03))", marginBottom: 10, transition: "all 0.2s ease"
            }}
        >
            <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12, color: "var(--text-sub, rgba(255,255,255,0.4))", fontWeight: 700 }}>{label}</div>
                <div style={{
                    fontSize: 15, fontWeight: 800, marginTop: 4,
                    color: (!values || values.length === 0) ? "var(--text-sub, rgba(255,255,255,0.3))" : color
                }}>
                    {summary}
                </div>
            </div>
            <RightOutlined style={{ fontSize: 12, color: "var(--text-sub, rgba(255,255,255,0.3))" }} />
        </div>
    );
};

const FullScreenPickerView = ({ title, options, fieldName, form, onBack, themeColor = "#0096FF", isDarkMode = true }) => {
    const [search, setSearch] = useState("");
    const [selectedValues, setSelectedValues] = useState(() => form.getFieldValue(fieldName) || []);

    const filteredOptions = options.filter(opt => opt.toLowerCase().includes(search.toLowerCase()));

    const toggleSelection = (opt) => {
        const uOpt = String(opt).toUpperCase();
        const currentUpper = selectedValues.map(v => String(v).toUpperCase());
        const newValues = currentUpper.includes(uOpt)
            ? selectedValues.filter(v => String(v).toUpperCase() !== uOpt)
            : [...selectedValues, opt];
        setSelectedValues(newValues);
    };

    const handleDone = () => {
        form.setFieldsValue({ [fieldName]: selectedValues });
        onBack();
    };

    return (
        <div style={{ background: "var(--bg-main, #0D1526)", flex: 1, display: "flex", flexDirection: "column", overflow: "hidden" }}>
            <div style={{ padding: "0 24px", position: "sticky", top: 0, zIndex: 10, background: "var(--bg-main, #0D1526)", borderBottom: "1px solid var(--card-border, rgba(255,255,255,0.1))" }}>
                <GrabHandle />
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20, marginTop: 12 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                        <Button
                            icon={<ArrowLeftOutlined />}
                            type="text"
                            style={{ fontSize: 18, color: "var(--text-main, #FFFFFF)", padding: 0 }}
                            onClick={onBack}
                        />
                        <div>
                            <div style={{ fontSize: 10, fontWeight: 800, color: "#38BDF8", letterSpacing: "1px", textTransform: "uppercase" }}>Selection</div>
                            <div style={{ margin: 0, fontWeight: 900, fontSize: 18, color: "var(--text-main, #FFFFFF)" }}>{title}</div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div style={{ padding: "16px 24px", background: "var(--bg-main, #091120)", borderBottom: "1px solid var(--card-border, rgba(255,255,255,0.05))" }}>
                <Input
                    prefix={<SearchOutlined style={{ color: "var(--text-sub, rgba(255,255,255,0.3))" }} />}
                    placeholder={`Search ${title.toLowerCase()}...`}
                    variant="borderless"
                    style={{ width: "100%", background: "var(--vivid-subtle-bg, rgba(255,255,255,0.05))", borderRadius: 12, height: 44, fontSize: 15, color: "var(--text-main, #FFFFFF)" }}
                    value={search}
                    onChange={e => setSearch(e.target.value)}
                />
            </div>

            <div style={{ padding: "0 24px", flex: 1, overflowY: "auto" }}>
                <div style={{ padding: "12px 0 30px" }}>
                    {filteredOptions.length > 0 ? filteredOptions.map(opt => {
                        const isSelected = selectedValues.map(v => String(v).toUpperCase()).includes(String(opt).toUpperCase());
                        return (
                            <div
                                key={opt}
                                onClick={() => toggleSelection(opt)}
                                style={{
                                    display: "flex", alignItems: "center", justifyContent: "space-between",
                                    padding: "16px 20px",
                                    borderRadius: 16,
                                    background: isSelected ? `${themeColor}15` : "var(--vivid-subtle-bg, rgba(255,255,255,0.02))",
                                    border: isSelected ? `2px solid ${themeColor}` : "2px solid var(--card-border, rgba(255,255,255,0.05))",
                                    marginBottom: 10,
                                    transition: "all 0.2s ease",
                                    cursor: "pointer"
                                }}
                            >
                                <div style={{ fontSize: 16, fontWeight: isSelected ? 800 : 600, color: isSelected ? themeColor : "var(--text-main, rgba(255,255,255,0.6))" }}>
                                    {formatLabel(opt)}
                                </div>
                                <CustomCheckbox checked={isSelected} themeColor={themeColor} />
                            </div>
                        );
                    }) : (
                        <div style={{ textAlign: "center", padding: "60px 0", color: "var(--text-sub, rgba(255,255,255,0.3))", fontSize: 14 }}>No {title.toLowerCase()} found</div>
                    )}
                </div>
            </div>
            
            <div style={{ padding: "20px 24px 30px", background: "var(--bg-main, #0D1526)", borderTop: "1px solid var(--card-border, rgba(255,255,255,0.1))" }}>
                <Button type="primary" block size="large" onClick={handleDone} style={{ height: 56, borderRadius: 16, fontSize: 16, fontWeight: 900, background: "var(--theme-primary)", border: "none", color: "#fff" }}>
                    Done ({selectedValues.length})
                </Button>
            </div>
        </div>
    );
};

const MainView = ({ 
    preferencesForm, updatePrefsMutation, watchCategories, watchTravelStyle, watchActivityLevel, 
    watchCuisines, watchDietary, watchAccessibility, watchTripPace, watchAccommodationType, 
    watchTransportPreference, watchLanguage, watchSpokenLanguages,
    showMoreTravel, setShowMoreTravel, showMoreAccommodation, setShowMoreAccommodation,
    showMoreTransport, setShowMoreTransport, showAdvanced, setShowAdvanced,
    handleOpenPicker, onClose,
    accentBlue, accentOrange, accentRed, accentPurple, accentGreen,
    optionTravelStyle, optionTripPace, optionAccommodationType, optionTransportPreference, optionLanguages,
    isDarkMode = true
}) => (
    <div style={{ background: "var(--bg-main, #0D1526)", height: "100%", display: "flex", flexDirection: "column", overflow: "hidden" }}>
        <div style={{ 
            padding: "0 24px", background: "var(--bg-main, #0D1526)", zIndex: 10,
            paddingBottom: "12px", borderBottom: "1px solid var(--card-border, rgba(255,255,255,0.1))"
        }}>
            <GrabHandle />
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20, marginTop: 12 }}>
                <div style={{ fontFamily: "var(--font-display)", fontVariationSettings: "'SOFT' 80, 'WONK' 1", fontSize: 26, fontWeight: 800, color: "var(--text-main, #FFFFFF)", letterSpacing: "-1px" }}>Preferences</div>
                <Button
                    icon={<CloseOutlined style={{ fontSize: 14 }} />}
                    type="text"
                    style={{
                        color: "var(--text-main, #FFFFFF)", padding: 0, width: 36, height: 36,
                        borderRadius: "50%", background: "var(--card-border, rgba(255,255,255,0.1))",
                        display: "flex", alignItems: "center", justifyContent: "center"
                    }}
                    onClick={onClose}
                />
            </div>
        </div>

        <div style={{ flex: 1, overflowY: "auto", padding: "0 24px 40px" }}>
            <Form form={preferencesForm} layout="vertical" onFinish={(v) => updatePrefsMutation.mutate(v)}>
                <Form.Item name="favoriteCategories" noStyle><input type="hidden" /></Form.Item>
                <Form.Item name="cuisinePreferences" noStyle><input type="hidden" /></Form.Item>
                <Form.Item name="dietaryRestrictions" noStyle><input type="hidden" /></Form.Item>
                <Form.Item name="accessibilityNeeds" noStyle><input type="hidden" /></Form.Item>
                <Form.Item name="spokenLanguages" noStyle><input type="hidden" /></Form.Item>
                <Form.Item name="travelStyle" noStyle><input type="hidden" /></Form.Item>
                <Form.Item name="tripPace" noStyle><input type="hidden" /></Form.Item>
                <Form.Item name="accommodationType" noStyle><input type="hidden" /></Form.Item>
                <Form.Item name="transportPreference" noStyle><input type="hidden" /></Form.Item>
                <Form.Item name="preferredLanguage" noStyle><input type="hidden" /></Form.Item>
                <Form.Item name="activityLevel" noStyle><input type="hidden" /></Form.Item>

                <FieldLabel text="Travel Preferences" />
                <ChipSelector
                    options={optionTravelStyle}
                    value={watchTravelStyle}
                    isMulti={true}
                    onChange={v => preferencesForm.setFieldsValue({ travelStyle: v })}
                    color={accentBlue}
                    maxVisible={5}
                    isExpanded={showMoreTravel}
                    onToggleMore={() => setShowMoreTravel(!showMoreTravel)}
                />

                <FieldLabel text="Favorite Categories" />
                <ChipSelector options={watchCategories} value={watchCategories} isMulti={true} color={accentBlue} maxVisible={3} />
                <MultiSelectRow label="Select categories" values={watchCategories} color={accentBlue} onClick={() => handleOpenPicker('categories')} />

                <FieldLabel text="Daily Budget" />
                <Row gutter={10}>
                    <Col span={8}>
                        <Form.Item name="dailyBudget" noStyle>
                            <ConfigProvider
                                theme={{
                                    token: {
                                        colorText: 'var(--text-main, #FFFFFF)',
                                        colorBgContainer: 'var(--vivid-subtle-bg, rgba(255,255,255,0.08))',
                                        colorBorder: 'transparent',
                                        colorTextPlaceholder: 'rgba(255,255,255,0.5)',
                                    }
                                }}
                            >
                                <InputNumber
                                    placeholder="150"
                                    style={{ 
                                        width: '100%', borderRadius: 12, height: 48, 
                                        display: 'flex', alignItems: 'center', 
                                        background: "var(--vivid-subtle-bg, transparent)", fontSize: 16, fontWeight: 800
                                    }}
                                />
                            </ConfigProvider>
                        </Form.Item>
                    </Col>
                    <Col span={7}>
                        <Form.Item name="budgetCurrency" noStyle>
                            <CurrencySelector isDarkMode={isDarkMode} />
                        </Form.Item>
                    </Col>
                </Row>

                <FieldLabel text="Activity Level" />
                <SegmentedControl isDarkMode={isDarkMode} options={["LOW", "MODERATE", "HIGH"]} value={watchActivityLevel} onChange={v => preferencesForm.setFieldsValue({ activityLevel: v })} />

                <FieldLabel text="Cuisine Preferences" />
                <ChipSelector options={watchCuisines} value={watchCuisines} isMulti={true} color={accentOrange} maxVisible={3} />
                <MultiSelectRow label="Select cuisines" values={watchCuisines} color={accentOrange} onClick={() => handleOpenPicker('cuisines')} />

                <FieldLabel text="Dietary Restrictions" subtext="Used by AI filter" />
                <ChipSelector options={watchDietary} value={watchDietary} isMulti={true} color={accentRed} maxVisible={3} />
                <MultiSelectRow label="Select dietary" values={watchDietary} color={accentRed} onClick={() => handleOpenPicker('dietary')} />

                <FieldLabel text="Accessibility Needs" />
                <MultiSelectRow label="Select accessibility" values={watchAccessibility} color={accentPurple} onClick={() => handleOpenPicker('accessibility')} />

                <FieldLabel text="Trip Pace" />
                <SegmentedControl isDarkMode={isDarkMode} options={optionTripPace} value={watchTripPace} onChange={v => preferencesForm.setFieldsValue({ tripPace: v })} />

                <FieldLabel text="Accommodation" />
                <ChipSelector options={optionAccommodationType} value={watchAccommodationType} onChange={v => preferencesForm.setFieldsValue({ accommodationType: v })} color={accentBlue} maxVisible={3} isExpanded={showMoreAccommodation} onToggleMore={() => setShowMoreAccommodation(!showMoreAccommodation)} />

                <FieldLabel text="Transport" />
                <ChipSelector options={optionTransportPreference} value={watchTransportPreference} onChange={v => preferencesForm.setFieldsValue({ transportPreference: v })} color={accentBlue} maxVisible={3} isExpanded={showMoreTransport} onToggleMore={() => setShowMoreTransport(!showMoreTransport)} />

                <FieldLabel text="Languages" />
                <ChipSelector options={optionLanguages} value={watchLanguage} onChange={v => preferencesForm.setFieldsValue({ preferredLanguage: v })} color={accentBlue} circle={true} maxVisible={7} />
                <MultiSelectRow label="Spoken languages" values={watchSpokenLanguages} color={accentGreen} onClick={() => handleOpenPicker('spokenLanguages')} />
            </Form>
        </div>

        <div style={{ padding: "20px 24px 30px", display: "flex", gap: 12, background: "var(--bg-main, #0D1526)", borderTop: "1px solid var(--card-border, rgba(255,255,255,0.1))", zIndex: 10 }}>
            <Button block size="large" onClick={onClose} style={{ height: 56, borderRadius: 16, fontSize: 16, fontWeight: 800, color: "var(--text-main, #FFFFFF)", background: "var(--card-border, rgba(255,255,255,0.1))", border: "none" }}>Cancel</Button>
            <Button type="primary" block size="large" onClick={() => preferencesForm.submit()} loading={updatePrefsMutation.isPending} style={{ height: 56, borderRadius: 16, fontSize: 16, fontWeight: 800, background: "var(--theme-primary)", border: "none", color: "#fff" }}>Save</Button>
        </div>
    </div>
);

export default function PreferencesModal({ open, onClose, isDarkMode, themeClass }) {
    const queryClient = useQueryClient();
    const [preferencesForm] = Form.useForm();
    const { data: preferences } = useUserPreferences();
    const [view, setView] = useState("MAIN");
    const [pickerField, setPickerField] = useState(null);
    const [showAdvanced, setShowAdvanced] = useState(false);
    const [showMoreTravel, setShowMoreTravel] = useState(false);
    const [showMoreAccommodation, setShowMoreAccommodation] = useState(false);
    const [showMoreTransport, setShowMoreTransport] = useState(false);

    useEffect(() => {
        if (open && preferences && view === 'MAIN') {
            preferencesForm.setFieldsValue({
                favoriteCategories: preferences.favoriteCategories || [],
                cuisinePreferences: preferences.cuisinePreferences || [],
                dietaryRestrictions: preferences.dietaryRestrictions || [],
                accessibilityNeeds: preferences.accessibilityNeeds || [],
                spokenLanguages: preferences.spokenLanguages || [],
                travelStyle: preferences.travelStyle,
                tripPace: preferences.tripPace,
                accommodationType: preferences.accommodationType,
                transportPreference: preferences.transportPreference,
                preferredLanguage: preferences.preferredLanguage || 'EN',
                activityLevel: preferences.activityLevel,
                dailyBudget: preferences.dailyBudget,
                budgetCurrency: preferences.budgetCurrency || 'EUR',
            });
        }
    }, [open, preferences, preferencesForm, view]);

    const updatePrefsMutation = useMutation({
        mutationFn: (values) => userApi.updatePreferences(values),
        onSuccess: () => {
            message.success("Preferences updated");
            queryClient.invalidateQueries(["userPreferences"]);
            onClose();
        }
    });

    const handleOpenPicker = (field) => {
        setPickerField(field);
        setView('PICKER');
    };

    const pickerData = useMemo(() => {
        if (pickerField === 'categories') return { title: "Categories", options: ["MUSEUMS", "NATURE", "NIGHTLIFE", "SHOPPING", "FOOD", "BEACH", "HISTORY", "ADVENTURE", "ART", "MUSIC", "SPORTS", "RELAXATION"], color: isDarkMode ? "#38BDF8" : "#FF6B6B" };
        if (pickerField === 'cuisines') return { title: "Cuisines", options: ["ITALIAN", "FRENCH", "JAPANESE", "CHINESE", "MEXICAN", "INDIAN", "THAI", "SPANISH", "GREEK", "TURKISH", "LEBANESE", "VIETNAMESE", "KOREAN", "MEDITERRANEAN", "VEGETARIAN", "VEGAN", "LOCAL_SPECIALTY", "SEAFOOD", "BBQ"], color: "#F4A261" };
        if (pickerField === 'dietary') return { title: "Dietary", options: ["NO_RESTRICTIONS", "VEGETARIAN", "VEGAN", "PESCATARIAN", "GLUTEN_FREE", "DAIRY_FREE", "NUT_ALLERGY", "SHELLFISH_ALLERGY", "KOSHER", "HALAL", "KETO", "PALEO"], color: "#FF6B6B" };
        if (pickerField === 'accessibility') return { title: "Accessibility", options: ["WHEELCHAIR_ACCESSIBLE", "NO_STAIRS", "ELEVATOR", "VISUAL_IMPAIRMENT", "HEARING_IMPAIRMENT", "SERVICE_ANIMAL", "EASY_WALKING"], color: "#9C27B0" };
        if (pickerField === 'spokenLanguages') return { title: "Languages", options: ["en", "tr", "de", "fr", "es", "it", "pt", "ar", "zh", "ja", "ko", "ru", "nl", "sv", "no", "da", "fi", "pl", "el", "hi", "bn", "ur"], color: isDarkMode ? "#38BDF8" : "#FF6B6B" };
        return { title: "", options: [], color: "#000" };
    }, [pickerField]);

    const watchCategories = Form.useWatch('favoriteCategories', preferencesForm) || [];
    const watchCuisines = Form.useWatch('cuisinePreferences', preferencesForm) || [];
    const watchDietary = Form.useWatch('dietaryRestrictions', preferencesForm) || [];
    const watchAccessibility = Form.useWatch('accessibilityNeeds', preferencesForm) || [];
    const watchLanguage = Form.useWatch('preferredLanguage', preferencesForm);
    const watchTripPace = Form.useWatch('tripPace', preferencesForm);
    const watchActivityLevel = Form.useWatch('activityLevel', preferencesForm);
    const watchAccommodationType = Form.useWatch('accommodationType', preferencesForm);
    const watchTravelStyle = Form.useWatch('travelStyle', preferencesForm);
    const watchSpokenLanguages = Form.useWatch('spokenLanguages', preferencesForm) || [];
    const watchTransportPreference = Form.useWatch('transportPreference', preferencesForm);

    const optionTripPace = ["SLOW", "MODERATE", "FAST"];
    const optionAccommodationType = ["HOTEL", "HOSTEL", "APARTMENT", "RESORT", "BOUTIQUE", "ANY"];
    const optionTransportPreference = ["WALKING", "PUBLIC_TRANSPORT", "CAR_RENTAL", "TAXI", "ANY"];
    const optionTravelStyle = ["RELAXATION", "ADVENTURE", "LUXURY", "BACKPACKER", "CULTURAL", "NIGHTLIFE", "FAMILY", "ROMANTIC"];
    const optionLanguages = ["en", "tr", "de", "fr", "es", "it", "pt", "ar", "zh", "ja", "ko", "ru"];

    const accentBlue = isDarkMode ? "#38BDF8" : "#FF6B6B";
    const accentOrange = "#F4A261";
    const accentRed = "#FF6B6B";
    const accentPurple = "#9C27B0";
    const accentGreen = "#2DD4A8";

    return (
        <ConfigProvider
            theme={{
                components: {
                    Modal: {
                        contentBg: 'transparent',
                        paddingMD: 0,
                        borderRadiusLG: 40,
                        boxShadow: 'none',
                    },
                },
                token: {
                    colorTextPlaceholder: isDarkMode ? 'rgba(255,255,255,0.75)' : 'rgba(0,0,0,0.4)',
                }
            }}
        >
            <Modal
                open={open}
                onCancel={onClose}
                footer={null}
                closable={false}
                maskClosable={false}
                width={600}
                centered
                styles={{
                    body: {
                        height: 750,
                        overflowY: 'auto',
                        padding: 0,
                        display: 'flex',
                        flexDirection: 'column',
                        borderRadius: 40,
                        overscrollBehavior: 'contain'
                    },
                    content: {
                        background: 'transparent',
                        borderRadius: 40,
                        padding: 0,
                        border: 'none',
                        boxShadow: 'none',
                        overflow: 'hidden'
                    }
                }}
                modalRender={(modal) => (
                    <div className="modal-shell">
                        <div className={themeClass} style={{ height: "100%", display: "flex", flexDirection: "column" }}>
                            {modal}
                        </div>
                    </div>
                )}
            >
                {view === 'MAIN' ? (
                    <MainView 
                        isDarkMode={isDarkMode}
                        preferencesForm={preferencesForm} updatePrefsMutation={updatePrefsMutation} 
                        watchCategories={watchCategories} watchTravelStyle={watchTravelStyle} watchActivityLevel={watchActivityLevel} 
                        watchCuisines={watchCuisines} watchDietary={watchDietary} watchAccessibility={watchAccessibility} watchTripPace={watchTripPace} watchAccommodationType={watchAccommodationType} 
                        watchTransportPreference={watchTransportPreference} watchLanguage={watchLanguage} watchSpokenLanguages={watchSpokenLanguages}
                        showMoreTravel={showMoreTravel} setShowMoreTravel={setShowMoreTravel} showMoreAccommodation={showMoreAccommodation} setShowMoreAccommodation={setShowMoreAccommodation}
                        showMoreTransport={showMoreTransport} setShowMoreTransport={setShowMoreTransport} showAdvanced={showAdvanced} setShowAdvanced={setShowAdvanced}
                        handleOpenPicker={handleOpenPicker} onClose={onClose}
                        accentBlue={accentBlue} accentOrange={accentOrange} accentRed={accentRed} accentPurple={accentPurple} accentGreen={accentGreen}
                        optionTravelStyle={optionTravelStyle} optionTripPace={optionTripPace} optionAccommodationType={optionAccommodationType} optionTransportPreference={optionTransportPreference} optionLanguages={optionLanguages}
                    />
                ) : (
                    <FullScreenPickerView 
                        isDarkMode={isDarkMode}
                        title={pickerData.title} options={pickerData.options} fieldName={pickerField} form={preferencesForm} onBack={() => setView('MAIN')} themeColor={pickerData.color} 
                    />
                )}
            </Modal>
        </ConfigProvider>
    );
}

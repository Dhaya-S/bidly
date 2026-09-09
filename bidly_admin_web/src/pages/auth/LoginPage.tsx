import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Input, message } from 'antd';
import { CheckCircle2, ArrowLeft, ArrowRight, Lock } from 'lucide-react';
import { authApi } from '../../api/auth.api';
import { useAuthStore } from '../../store/auth.store';

export const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const { login } = useAuthStore();

  const [step, setStep] = useState<1 | 2>(1);
  const [email, setEmail] = useState<string>('admin@bidly.com');
  const [otp, setOtp] = useState<string[]>(['', '', '', '', '', '']);
  const [loading, setLoading] = useState<boolean>(false);
  const [timer, setTimer] = useState<number>(30);
  const [canResend, setCanResend] = useState<boolean>(false);

  const otpInputsRef = useRef<(HTMLInputElement | null)[]>([]);

  useEffect(() => {
    let interval: any;
    if (step === 2 && timer > 0) {
      interval = setInterval(() => {
        setTimer((prev) => prev - 1);
      }, 1000);
    } else if (timer === 0) {
      setCanResend(true);
    }
    return () => clearInterval(interval);
  }, [step, timer]);

  const maskEmail = (val: string) => {
    const parts = val.split('@');
    if (parts.length !== 2) return val;
    const name = parts[0];
    const domain = parts[1];
    const maskedName = name.length > 2 ? `${name.slice(0, 2)}•••${name.slice(-1)}` : `${name}•••`;
    const maskedDomain = domain.length > 3 ? `${domain[0]}•••${domain.slice(-2)}` : domain;
    return `${maskedName}@${maskedDomain}`;
  };

  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !email.includes('@')) {
      message.error('Please enter a valid email address');
      return;
    }
    setLoading(true);
    try {
      await authApi.sendOtp({ email });
      setLoading(false);
      setStep(2);
      setTimer(30);
      setCanResend(false);
      message.success(`OTP sent to ${email}`);
      setTimeout(() => otpInputsRef.current[0]?.focus(), 100);
    } catch {
      setLoading(false);
      message.error('Failed to send OTP. Please try again.');
    }
  };

  const handleOtpChange = (index: number, val: string) => {
    if (val.length > 1) {
      // Handle paste
      const digits = val.replace(/\D/g, '').slice(0, 6).split('');
      const newOtp = [...otp];
      digits.forEach((d, i) => {
        newOtp[i] = d;
      });
      setOtp(newOtp);
      const nextIndex = Math.min(digits.length, 5);
      otpInputsRef.current[nextIndex]?.focus();
      return;
    }

    const newOtp = [...otp];
    newOtp[index] = val;
    setOtp(newOtp);

    if (val && index < 5) {
      otpInputsRef.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      otpInputsRef.current[index - 1]?.focus();
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    const otpString = otp.join('');
    if (otpString.length !== 6) {
      message.error('Please enter all 6 digits of the OTP');
      return;
    }

    setLoading(true);
    try {
      await login(email, otpString);
      setLoading(false);
      message.success('Sign in successful! Welcome back.');
      navigate('/dashboard');
    } catch {
      setLoading(false);
      message.error('Invalid OTP. Please try again.');
    }
  };

  const handleResend = async () => {
    if (!canResend) return;
    setTimer(30);
    setCanResend(false);
    await authApi.sendOtp({ email });
    message.success('New OTP sent to your email.');
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        width: '100vw',
        background: 'linear-gradient(135deg, #0F4C4C 0%, #1A3A3A 50%, #0D2828 100%)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '24px',
        position: 'relative',
        boxSizing: 'border-box',
      }}
    >
      {/* Background ambient glowing blob */}
      <div
        style={{
          position: 'absolute',
          width: '500px',
          height: '500px',
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(13,148,136,0.15) 0%, rgba(0,0,0,0) 70%)',
          top: '20%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          pointerEvents: 'none',
        }}
      />

      <div
        style={{
          width: '100%',
          maxWidth: '460px',
          backgroundColor: '#FFFFFF',
          borderRadius: '16px',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.35)',
          padding: '40px 36px',
          position: 'relative',
          zIndex: 1,
        }}
      >
        {/* Brand Logo & Title */}
        <div style={{ textAlign: 'center', marginBottom: '28px' }}>
          <div
            style={{
              width: '48px',
              height: '48px',
              borderRadius: '12px',
              backgroundColor: '#0D9488',
              color: '#FFFFFF',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '24px',
              fontWeight: 800,
              boxShadow: '0 10px 15px -3px rgba(13, 148, 136, 0.3)',
              marginBottom: '12px',
            }}
          >
            B
          </div>
          <h1 style={{ fontSize: '22px', fontWeight: 700, color: '#0F172A', margin: '0 0 4px 0' }}>
            Bidly Admin
          </h1>
          <p style={{ fontSize: '13px', color: '#64748B', margin: 0 }}>
            Operations & Marketplace Control Panel
          </p>
        </div>

        {/* Stepper indicator */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '12px',
            marginBottom: '32px',
          }}
        >
          {/* Step 1 indicator */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <div
              style={{
                width: '20px',
                height: '20px',
                borderRadius: '50%',
                backgroundColor: step === 1 ? '#0D9488' : '#10B981',
                color: '#FFFFFF',
                fontSize: '11px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 600,
              }}
            >
              {step === 2 ? <CheckCircle2 size={13} /> : '1'}
            </div>
            <span
              style={{
                fontSize: '12px',
                fontWeight: step === 1 ? 600 : 500,
                color: step === 1 ? '#0F172A' : '#64748B',
              }}
            >
              Email
            </span>
          </div>

          <div style={{ width: '32px', height: '2px', backgroundColor: '#E2E8F0' }} />

          {/* Step 2 indicator */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <div
              style={{
                width: '20px',
                height: '20px',
                borderRadius: '50%',
                backgroundColor: step === 2 ? '#0D9488' : '#E2E8F0',
                color: step === 2 ? '#FFFFFF' : '#94A3B8',
                fontSize: '11px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 600,
              }}
            >
              2
            </div>
            <span
              style={{
                fontSize: '12px',
                fontWeight: step === 2 ? 600 : 500,
                color: step === 2 ? '#0F172A' : '#94A3B8',
              }}
            >
              Verify OTP
            </span>
          </div>
        </div>

        {step === 1 ? (
          /* Step 1: Email Form */
          <form onSubmit={handleSendOtp}>
            <div style={{ marginBottom: '24px' }}>
              <h2 style={{ fontSize: '18px', fontWeight: 600, color: '#0F172A', marginBottom: '6px' }}>
                Welcome back
              </h2>
              <p style={{ fontSize: '13px', color: '#64748B', margin: 0 }}>
                Enter your administrative email to receive a one-time verification code.
              </p>
            </div>

            <div style={{ marginBottom: '20px' }}>
              <label
                style={{
                  display: 'block',
                  fontSize: '13px',
                  fontWeight: 600,
                  color: '#334155',
                  marginBottom: '6px',
                }}
              >
                Email address
              </label>
              <Input
                type="email"
                size="large"
                placeholder="admin@bidly.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                style={{ borderRadius: '8px' }}
                autoFocus
              />
              <span style={{ display: 'block', fontSize: '11px', color: '#94A3B8', marginTop: '6px' }}>
                Authorized admin domains: @bidly.com
              </span>
            </div>

            <Button
              type="primary"
              htmlType="submit"
              size="large"
              block
              loading={loading}
              style={{
                backgroundColor: '#0D9488',
                height: '44px',
                fontSize: '14px',
                fontWeight: 600,
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px',
              }}
            >
              Send OTP <ArrowRight size={16} />
            </Button>
          </form>
        ) : (
          /* Step 2: OTP Verification Form */
          <form onSubmit={handleVerifyOtp}>
            <div style={{ marginBottom: '24px' }}>
              <h2 style={{ fontSize: '18px', fontWeight: 600, color: '#0F172A', marginBottom: '6px' }}>
                Verify your identity
              </h2>
              <p style={{ fontSize: '13px', color: '#64748B', margin: 0 }}>
                We sent a 6-digit OTP code to{' '}
                <strong style={{ color: '#0F172A' }}>{maskEmail(email)}</strong>
              </p>
            </div>

            {/* 6 OTP Inputs */}
            <div
              style={{
                display: 'flex',
                gap: '8px',
                justifyContent: 'center',
                marginBottom: '20px',
              }}
            >
              {otp.map((digit, idx) => (
                <input
                  key={idx}
                  ref={(el) => { otpInputsRef.current[idx] = el; }}
                  type="text"
                  inputMode="numeric"
                  maxLength={1}
                  value={digit}
                  onChange={(e) => handleOtpChange(idx, e.target.value)}
                  onKeyDown={(e) => handleKeyDown(idx, e)}
                  style={{
                    width: '46px',
                    height: '52px',
                    textAlign: 'center',
                    fontSize: '20px',
                    fontWeight: 700,
                    borderRadius: '8px',
                    border: '1.5px solid #CBD5E1',
                    outline: 'none',
                    backgroundColor: '#F8FAFC',
                    color: '#0F172A',
                    transition: 'border-color 0.2s',
                  }}
                  onFocus={(e) => (e.target.style.borderColor = '#0D9488')}
                  onBlur={(e) => (e.target.style.borderColor = '#CBD5E1')}
                />
              ))}
            </div>

            {/* Resend OTP row */}
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                fontSize: '12px',
                marginBottom: '24px',
              }}
            >
              <span style={{ color: '#64748B' }}>Didn't receive the OTP?</span>
              {canResend ? (
                <span
                  onClick={handleResend}
                  style={{ color: '#0D9488', fontWeight: 600, cursor: 'pointer' }}
                >
                  Resend OTP
                </span>
              ) : (
                <span style={{ color: '#94A3B8' }}>Resend in {timer}s</span>
              )}
            </div>

            <Button
              type="primary"
              htmlType="submit"
              size="large"
              block
              loading={loading}
              style={{
                backgroundColor: '#0D9488',
                height: '44px',
                fontSize: '14px',
                fontWeight: 600,
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px',
              }}
            >
              <Lock size={15} /> Verify & Sign In
            </Button>

            <div style={{ textAlign: 'center', marginTop: '16px' }}>
              <span
                onClick={() => setStep(1)}
                style={{
                  fontSize: '13px',
                  color: '#0D9488',
                  cursor: 'pointer',
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                  fontWeight: 500,
                }}
              >
                <ArrowLeft size={14} /> Change email address
              </span>
            </div>

            <div
              style={{
                marginTop: '20px',
                padding: '8px 12px',
                backgroundColor: '#F0FDFA',
                borderRadius: '6px',
                textAlign: 'center',
                fontSize: '11px',
                color: '#0F766E',
                border: '1px solid #CCFBF1',
              }}
            >
              Demo: enter any 6 digits (e.g. 123456) to sign in
            </div>
          </form>
        )}
      </div>

      <div style={{ marginTop: '24px', fontSize: '12px', color: '#94A3B8', textAlign: 'center' }}>
        © 2025 Bidly Technologies Pvt. Ltd. All rights reserved.
      </div>
    </div>
  );
};

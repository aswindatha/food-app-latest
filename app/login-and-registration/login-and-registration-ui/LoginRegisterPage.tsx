import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import styled, { keyframes, css } from 'styled-components';
import type { DefaultTheme } from 'styled-components';

// Types
type Role = {
  id: number;
  name: string;
  description: string;
};

type UserData = {
  id: number;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  roleId: number;
  roleName: string;
  isActive: boolean;
  emailVerified: boolean;
};

interface FormData {
  username: string;
  email: string;
  password: string;
  confirmPassword: string;
  firstName: string;
  lastName: string;
  phone: string;
  roleId: number;
}

interface LoginResponse {
  success: boolean;
  data: {
    user: UserData;
    sessionToken: string;
  };
}

interface RegisterResponse {
  success: boolean;
  data: {
    user: UserData;
    sessionToken: string;
  };
}

// Styled Components
const fadeIn = keyframes`
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
`;

const slideIn = keyframes`
  from { transform: translateY(-20px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
`;

const spin = keyframes`
  to { transform: rotate(360deg); }
`;

const AuthContainer = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  padding: 20px;
`;

const AuthCard = styled.div`
  background: white;
  border-radius: 16px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  padding: 40px;
  width: 100%;
  max-width: 450px;
  transition: all 0.3s ease;
  animation: ${fadeIn} 0.5s ease-out;
  
  &:hover {
    transform: translateY(-5px);
    box-shadow: 0 15px 35px rgba(0, 0, 0, 0.15);
  }
  
  @media (max-width: 480px) {
    padding: 30px 20px;
  }
`;

const Title = styled.h1`
  color: #2d3748;
  font-size: 28px;
  font-weight: 700;
  margin-bottom: 10px;
  text-align: center;
  animation: ${slideIn} 0.6s ease-out;
  
  @media (max-width: 480px) {
    font-size: 24px;
  }
`;

const Subtitle = styled.p`
  color: #718096;
  text-align: center;
  margin-bottom: 30px;
  font-size: 15px;
  animation: ${slideIn} 0.7s ease-out;
  
  @media (max-width: 480px) {
    font-size: 14px;
  }
`;

const FormGroup = styled.div`
  margin-bottom: 20px;
  position: relative;
  animation: ${slideIn} 0.8s ease-out;
  
  input, select {
    width: 100%;
    padding: 14px 16px;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    font-size: 15px;
    color: #2d3748;
    background-color: #f8fafc;
    transition: all 0.3s ease;
    
    &:focus {
      outline: none;
      border-color: #4299e1;
      box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.2);
      background-color: white;
    }
    
    &::placeholder {
      color: #a0aec0;
    }
  }
`;

const SubmitButton = styled.button`
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #4299e1 0%, #3182ce 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 10px;
  animation: ${slideIn} 0.9s ease-out;
  
  &:hover {
    background: linear-gradient(135deg, #3182ce 0%, #2b6cb0 100%);
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(49, 130, 206, 0.3);
  }
  
  &:disabled {
    background: #a0aec0;
    cursor: not-allowed;
    transform: none;
    box-shadow: none;
  }
`;

const ToggleForm = styled.div`
  text-align: center;
  margin-top: 25px;
  color: #4a5568;
  font-size: 14px;
  animation: ${slideIn} 1s ease-out;
`;

const ToggleButton = styled.button`
  background: none;
  border: none;
  color: #4299e1;
  font-weight: 600;
  cursor: pointer;
  padding: 0 5px;
  font-size: 14px;
  transition: color 0.2s ease;
  
  &:hover {
    color: #2b6cb0;
    text-decoration: underline;
  }
`;

interface AlertProps {
  type: 'error' | 'success';
  theme?: DefaultTheme;
}

const Alert = styled.div<AlertProps>`
  padding: 12px 16px;
  border-radius: 8px;
  margin-bottom: 20px;
  font-size: 14px;
  font-weight: 500;
  animation: ${slideIn} 0.5s ease-out;
  
  ${(props: AlertProps) => props.type === 'error' && css`
    background-color: #fff5f5;
    color: #e53e3e;
    border: 1px solid #fc8181;
  `}
  
  ${(props: AlertProps) => props.type === 'success' && css`
    background-color: #f0fff4;
    color: #38a169;
    border: 1px solid #9ae6b4;
  `}
`;

const ForgotPassword = styled.div`
  text-align: right;
  margin: -10px 0 15px;
  
  a {
    color: #718096;
    font-size: 13px;
    text-decoration: none;
    transition: color 0.2s ease;
    
    &:hover {
      color: #4299e1;
      text-decoration: underline;
    }
  }
`;

const Spinner = styled.span`
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 3px solid rgba(255, 255, 255, 0.3);
  border-radius: 50%;
  border-top-color: white;
  animation: ${spin} 1s ease-in-out infinite;
`;

const LoginRegisterPage: React.FC = () => {
  const [isLogin, setIsLogin] = useState(true);
  const [roles, setRoles] = useState<Role[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  const [formData, setFormData] = useState<FormData>({
    username: '',
    email: '',
    password: '',
    confirmPassword: '',
    firstName: '',
    lastName: '',
    phone: '',
    roleId: 0,
  });

  const navigate = useNavigate();
  const API_BASE_URL = 'http://localhost:8080/api/auth';

  useEffect(() => {
    const fetchRoles = async () => {
      try {
        const response = await axios.get<{ success: boolean; data: Record<string, Role> }>(`${API_BASE_URL}/roles`);
        if (response.data.success && response.data.data) {
          setRoles(Object.values(response.data.data) as Role[]);
        }
      } catch (err) {
        console.error('Error fetching roles:', err);
      }
    };

    fetchRoles();
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData((prev: typeof formData) => ({
      ...prev,
      [name]: name === 'roleId' ? parseInt(value) || 0 : value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setLoading(true);

    try {
      if (isLogin) {
        const response = await axios.post<LoginResponse>(`${API_BASE_URL}/login`, {
          username: formData.username,
          password: formData.password
        });

        if (response.data.success) {
          const { user, sessionToken } = response.data.data;
          localStorage.setItem('authToken', sessionToken);
          localStorage.setItem('user', JSON.stringify(user));
          
          redirectBasedOnRole(user.roleName);
        }
      } else {
        if (formData.password !== formData.confirmPassword) {
          throw new Error('Passwords do not match');
        }

        const response = await axios.post<RegisterResponse>(`${API_BASE_URL}/register`, {
          username: formData.username,
          email: formData.email,
          password: formData.password,
          firstName: formData.firstName,
          lastName: formData.lastName,
          phone: formData.phone,
          roleId: formData.roleId
        });

        if (response.data.success) {
          setSuccess('Registration successful! Please log in.');
          setIsLogin(true);
          setFormData({
            username: '',
            email: '',
            password: '',
            confirmPassword: '',
            firstName: '',
            lastName: '',
            phone: '',
            roleId: 0,
          });
        }
      }
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  // Redirect user based on their role
  const redirectBasedOnRole = (roleName: string) => {
    switch (roleName.toLowerCase()) {
      case 'donor':
        navigate('/donor/dashboard');
        break;
      case 'volunteer':
        navigate('/volunteer/dashboard');
        break;
      case 'organization':
        navigate('/organization/dashboard');
        break;
      case 'administrator':
        navigate('/admin/dashboard');
        break;
      default:
        navigate('/');
    }
  };

  // Toggle between login and register forms
  const toggleForm = () => {
    setIsLogin(!isLogin);
    setError('');
    setSuccess('');
  };

  return (
    <AuthContainer>
      <AuthCard>
        <Title>{isLogin ? 'Welcome Back!' : 'Create an Account'}</Title>
        <Subtitle>
          {isLogin ? 'Sign in to continue to FoodShare' : 'Join our community to reduce food waste'}
        </Subtitle>

        {error && <Alert type="error">{error}</Alert>}
        {success && <Alert type="success">{success}</Alert>}

        <form onSubmit={handleSubmit}>
          {!isLogin && (
            <>
              <FormGroup>
                <input
                  type="text"
                  name="firstName"
                  value={formData.firstName}
                  onChange={handleChange}
                  placeholder="First Name"
                  required={!isLogin}
                />
              </FormGroup>
              <FormGroup>
                <input
                  type="text"
                  name="lastName"
                  value={formData.lastName}
                  onChange={handleChange}
                  placeholder="Last Name"
                  required={!isLogin}
                />
              </FormGroup>
              <FormGroup>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  placeholder="Email Address"
                  required={!isLogin}
                />
              </FormGroup>
              <FormGroup>
                <input
                  type="tel"
                  name="phone"
                  value={formData.phone}
                  onChange={handleChange}
                  placeholder="Phone Number (Optional)"
                />
              </FormGroup>
              <FormGroup>
                <select
                  name="roleId"
                  value={formData.roleId}
                  onChange={handleChange}
                  required={!isLogin}
                >
                  <option value="">Select Role</option>
                  {roles.map((role: Role) => (
                    <option key={role.id} value={role.id}>
                      {role.name.charAt(0).toUpperCase() + role.name.slice(1)}
                    </option>
                  ))}
                </select>
              </FormGroup>
            </>
          )}

          <FormGroup>
            <input
              type="text"
              name="username"
              value={formData.username}
              onChange={handleChange}
              placeholder="Username"
              required
            />
          </FormGroup>
          <FormGroup>
            <input
              type="password"
              name="password"
              value={formData.password}
              onChange={handleChange}
              placeholder="Password"
              required
            />
          </FormGroup>
          {!isLogin && (
            <FormGroup>
              <input
                type="password"
                name="confirmPassword"
                value={formData.confirmPassword}
                onChange={handleChange}
                placeholder="Confirm Password"
                required={!isLogin}
              />
            </FormGroup>
          )}

          {isLogin && (
            <ForgotPassword>
              <a href="/forgot-password">Forgot Password?</a>
            </ForgotPassword>
          )}

          <SubmitButton type="submit" disabled={loading}>
            {loading ? (
              <Spinner />
            ) : isLogin ? (
              'Sign In'
            ) : (
              'Create Account'
            )}
          </SubmitButton>
        </form>

        <ToggleForm>
          {isLogin ? "Don't have an account? " : 'Already have an account? '}
          <ToggleButton type="button" onClick={toggleForm}>
            {isLogin ? 'Sign Up' : 'Sign In'}
          </ToggleButton>
        </ToggleForm>
      </AuthCard>
    </AuthContainer>
  );
};

export default LoginRegisterPage;
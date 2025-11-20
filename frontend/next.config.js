/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'standalone', // Required for containerization
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8080',
  },
  async rewrites() {
    // Use a default API URL if not provided during build
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8080';
    const cleanUrl = apiUrl.replace(/\/$/, '').trim();
    
    // Validate URL format - ensure it's a valid URL
    if (!cleanUrl || cleanUrl === 'undefined' || cleanUrl === '' || 
        (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://'))) {
      return [
        {
          source: '/api/:path*',
          destination: 'http://127.0.0.1:8080/:path*',
        },
      ];
    }
    
    return [
      {
        source: '/api/:path*',
        destination: `${cleanUrl}/:path*`,
      },
    ]
  },
}

module.exports = nextConfig


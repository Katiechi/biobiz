import type { Metadata } from "next";
import { Geist } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "BioBiz - Digital Business Card App",
  description:
    "Create, share, and manage your digital business card. Share via QR code, record meetings with AI notes, and grow your network. Free forever.",
  openGraph: {
    title: "BioBiz - Digital Business Card App",
    description:
      "Create and share digital business cards via QR code. AI-powered meeting notes. Free forever.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${geistSans.variable} antialiased`}>
        {children}
      </body>
    </html>
  );
}

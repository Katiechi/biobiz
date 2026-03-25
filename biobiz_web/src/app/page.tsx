import Image from "next/image";

export default function Home() {
  return (
    <div className="min-h-screen bg-[#1C1210] text-white">
      {/* Header */}
      <header className="flex items-center justify-between px-6 py-4 max-w-6xl mx-auto">
        <div className="flex items-center gap-3">
          <Image src="/logo.png" alt="BioBiz" width={36} height={36} className="rounded-lg" />
          <span className="text-xl font-bold">BioBiz</span>
        </div>
        <nav className="flex items-center gap-6">
          <a href="#features" className="text-sm text-gray-400 hover:text-white transition-colors">
            Features
          </a>
          <a href="#download" className="text-sm px-4 py-2 bg-[#C62828] hover:bg-[#AD1F1F] rounded-lg transition-colors font-medium">
            Download
          </a>
        </nav>
      </header>

      {/* Hero */}
      <main className="max-w-6xl mx-auto px-6 pt-16 pb-32">
        <div className="text-center max-w-3xl mx-auto">
          <Image
            src="/logo.png"
            alt="BioBiz Logo"
            width={180}
            height={180}
            className="mx-auto mb-8 rounded-2xl"
          />
          <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-[#C62828]/15 rounded-full text-[#EF5350] text-sm font-medium mb-6">
            <span className="w-2 h-2 bg-[#C62828] rounded-full animate-pulse" />
            Available on Android
          </div>
          <h1 className="text-5xl md:text-6xl font-bold leading-tight mb-6">
            Your business card,{" "}
            <span className="text-[#D4A537]">reimagined</span>
          </h1>
          <p className="text-xl text-gray-400 mb-10 max-w-xl mx-auto">
            Create a stunning digital business card in under 60 seconds. Share
            via QR code. Record meetings with AI-powered notes. 100% free.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a
              href="#download"
              className="w-full sm:w-auto px-8 py-4 bg-[#C62828] hover:bg-[#AD1F1F] text-white rounded-xl font-semibold transition-colors text-center text-lg"
            >
              Download Free APK
            </a>
            <a
              href="#features"
              className="w-full sm:w-auto px-8 py-4 bg-white/5 hover:bg-white/10 text-white rounded-xl font-semibold border border-white/10 transition-colors text-center"
            >
              See how it works
            </a>
          </div>
        </div>

        {/* Features */}
        <section id="features" className="mt-32">
          <h2 className="text-3xl font-bold text-center mb-4">
            Everything you need to network smarter
          </h2>
          <p className="text-center text-gray-400 mb-16">All features free. No premium tiers.</p>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="🪪"
              title="Digital Business Card"
              description="Create a beautiful card with your photo, logo, contact info, and social links. Customize colors and layout."
            />
            <FeatureCard
              icon="📱"
              title="QR Code Sharing"
              description="Share your card via QR code instantly. When someone scans your code, they get all your details automatically."
            />
            <FeatureCard
              icon="🔄"
              title="Auto Exchange"
              description="When you scan someone's card, both of you get each other's contact details saved automatically."
            />
            <FeatureCard
              icon="🎙️"
              title="AI Meeting Notes"
              description="Record meetings and get AI-powered transcripts with summaries, key insights, and action items."
            />
            <FeatureCard
              icon="📊"
              title="Card Analytics"
              description="Track who views your card, how many times it's shared, and monitor your networking activity."
            />
            <FeatureCard
              icon="📇"
              title="Contact Management"
              description="All your scanned contacts in one place with notes, social links, and one-tap call or email."
            />
          </div>
        </section>

        {/* How it works */}
        <section className="mt-32">
          <h2 className="text-3xl font-bold text-center mb-16">
            How it works
          </h2>
          <div className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
            <StepCard
              step="1"
              title="Create your card"
              description="Sign up, add your details, photo, logo, and social links. Pick your card color."
            />
            <StepCard
              step="2"
              title="Share your QR code"
              description="Show your QR code at meetings, conferences, or anywhere you network."
            />
            <StepCard
              step="3"
              title="Grow your network"
              description="Contacts are saved automatically for both parties. Add notes and stay connected."
            />
          </div>
        </section>

        {/* Download */}
        <section id="download" className="mt-32 text-center">
          <div className="bg-gradient-to-br from-[#C62828] to-[#AD1F1F] rounded-3xl p-12">
            <Image
              src="/logo.png"
              alt="BioBiz"
              width={80}
              height={80}
              className="mx-auto mb-6 rounded-xl"
            />
            <h2 className="text-3xl font-bold mb-4">
              Ready to ditch paper cards?
            </h2>
            <p className="text-red-100 mb-8 max-w-md mx-auto">
              Download BioBiz now. Free forever, no hidden costs.
            </p>
            <a
              href="https://github.com/Katiechi/biobiz/releases/latest/download/biobiz-v1.0.0.apk"
              download
              className="inline-block px-8 py-4 bg-white text-[#C62828] rounded-xl font-semibold hover:bg-red-50 transition-colors text-lg"
            >
              Download APK (Android)
            </a>
            <p className="text-red-200 text-sm mt-4">
              iOS coming soon
            </p>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-white/10 py-8 px-6">
        <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <Image src="/logo.png" alt="BioBiz" width={24} height={24} className="rounded" />
            <span className="text-sm text-gray-500">
              BioBiz &copy; {new Date().getFullYear()}
            </span>
          </div>
          <div className="flex gap-6 text-sm text-gray-500">
            <a href="/privacy.html" className="hover:text-gray-300 transition-colors">
              Privacy Policy
            </a>
            <a href="/terms.html" className="hover:text-gray-300 transition-colors">
              Terms of Service
            </a>
            <a href="mailto:support@biobiz.app" className="hover:text-gray-300 transition-colors">
              Support
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}

function FeatureCard({
  icon,
  title,
  description,
}: {
  icon: string;
  title: string;
  description: string;
}) {
  return (
    <div className="bg-white/5 backdrop-blur rounded-2xl p-6 border border-white/5 hover:border-[#D4A537]/30 transition-colors">
      <div className="text-3xl mb-4">{icon}</div>
      <h3 className="text-lg font-semibold mb-2">{title}</h3>
      <p className="text-gray-400 text-sm leading-relaxed">{description}</p>
    </div>
  );
}

function StepCard({
  step,
  title,
  description,
}: {
  step: string;
  title: string;
  description: string;
}) {
  return (
    <div className="text-center">
      <div className="w-12 h-12 bg-[#D4A537] rounded-full flex items-center justify-center mx-auto mb-4 text-black font-bold text-lg">
        {step}
      </div>
      <h3 className="text-lg font-semibold mb-2">{title}</h3>
      <p className="text-gray-400 text-sm">{description}</p>
    </div>
  );
}

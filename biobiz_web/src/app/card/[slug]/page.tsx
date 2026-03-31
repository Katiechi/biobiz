// Story 4.4: Public card viewer — SSR page
import { supabase } from '@/lib/supabase';
import { notFound } from 'next/navigation';
import type { Metadata } from 'next';

interface Props {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const { data: card } = await supabase
    .from('cards')
    .select('first_name, last_name, job_title, company')
    .eq('slug', slug)
    .eq('is_active', true)
    .single();

  if (!card) return { title: 'Card Not Found' };

  const name = `${card.first_name} ${card.last_name || ''}`.trim();
  const title = card.job_title ? `${name} — ${card.job_title}` : name;
  const description = card.company ? `${name} at ${card.company}` : `View ${name}'s digital business card`;

  return {
    title,
    description,
    openGraph: { title, description },
  };
}

export default async function CardPage({ params }: Props) {
  const { slug } = await params;

  const { data: card } = await supabase
    .from('cards')
    .select('*')
    .eq('slug', slug)
    .eq('is_active', true)
    .single();

  if (!card) notFound();

  const { data: contactFields } = await supabase
    .from('card_contact_fields')
    .select('*')
    .eq('card_id', card.id)
    .order('sort_order');

  const { data: socialLinks } = await supabase
    .from('card_social_links')
    .select('*')
    .eq('card_id', card.id)
    .order('sort_order');

  supabase.from('card_events').insert({
    card_id: card.id,
    event_type: 'view',
  });

  const cardColor = card.card_color || '#000000';
  const name = `${card.first_name} ${card.last_name || ''}`.trim();

  return (
    <div className="min-h-screen bg-[#1C1210] flex flex-col items-center justify-center px-4 py-8">
      {/* Card */}
      <div
        className="w-full max-w-sm rounded-3xl shadow-2xl overflow-hidden"
        style={{ backgroundColor: cardColor }}
      >
        {/* Cover image */}
        {card.cover_image_url && (
          <div className="h-24 w-full overflow-hidden">
            <img src={card.cover_image_url} alt="" className="w-full h-full object-cover" />
          </div>
        )}

        <div className="px-6 pt-6 pb-8 text-white text-center">
          {/* Logo */}
          {card.logo_url && (
            <div className="mb-4">
              <img src={card.logo_url} alt="Logo" className="h-8 mx-auto object-contain" />
            </div>
          )}

          {/* Profile Image */}
          <div className="mb-4">
            {card.profile_image_url ? (
              <img
                src={card.profile_image_url}
                alt={name}
                className="w-20 h-20 rounded-full mx-auto object-cover border-[3px] border-white/20"
              />
            ) : (
              <div className="w-20 h-20 rounded-full mx-auto bg-white/20 flex items-center justify-center text-3xl font-bold">
                {card.first_name?.[0]?.toUpperCase() || '?'}
              </div>
            )}
          </div>

          {/* Name */}
          <h1 className="text-xl font-bold leading-tight">{name}</h1>

          {/* Title & Company */}
          {card.job_title && (
            <p className="text-white/80 text-sm mt-1">{card.job_title}</p>
          )}
          {card.company && (
            <p className="text-white/60 text-sm">{card.company}</p>
          )}

          {/* Headline */}
          {card.headline && (
            <p className="text-white/50 text-xs italic mt-2 px-4">{card.headline}</p>
          )}

          {/* Divider */}
          <div className="my-5 border-t border-white/20 mx-4" />

          {/* Contact Fields */}
          <div className="space-y-2.5">
            {contactFields?.map((field) => (
              <a
                key={field.id}
                href={getContactLink(field.field_type, field.value)}
                className="flex items-center gap-3 px-4 py-2.5 rounded-xl bg-white/5 hover:bg-white/10 transition-colors text-left"
              >
                <span className="text-base shrink-0">
                  <ContactIcon type={field.field_type} />
                </span>
                <span className="text-white/90 text-sm truncate">{field.value}</span>
              </a>
            ))}
          </div>

          {/* Social Links */}
          {socialLinks && socialLinks.length > 0 && (
            <div className="flex justify-center gap-3 mt-4 flex-wrap">
              {socialLinks.map((link) => (
                <a
                  key={link.id}
                  href={link.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-10 h-10 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors"
                  title={link.platform}
                >
                  <span className="text-sm font-semibold text-white/80">
                    <SocialIcon platform={link.platform} />
                  </span>
                </a>
              ))}
            </div>
          )}

          {/* Action Buttons */}
          <div className="mt-6 space-y-3">
            {/* Open in App — tries deep link */}
            <a
              href={`io.supabase.biobiz://card/${slug}`}
              className="block w-full py-3 bg-[#D4A537] text-gray-900 rounded-xl font-semibold hover:bg-[#E8C96A] transition-colors text-center text-sm"
            >
              Open in BioBiz App
            </a>
            <a
              href={`/api/card/${slug}/vcard`}
              className="block w-full py-3 bg-white text-gray-900 rounded-xl font-semibold hover:bg-white/90 transition-colors text-center text-sm"
            >
              Save to Contacts
            </a>
          </div>

          {/* Branding */}
          {!card.remove_branding && (
            <p className="text-white/30 text-[10px] mt-5 tracking-wide uppercase">Powered by BioBiz</p>
          )}
        </div>
      </div>

      {/* Download banner */}
      <div className="w-full max-w-sm mt-5">
        <div className="bg-white/5 backdrop-blur rounded-2xl p-5 border border-white/10 text-center">
          <p className="text-white font-semibold text-sm mb-1">Want to exchange cards?</p>
          <p className="text-gray-400 text-xs mb-4 leading-relaxed">
            Get BioBiz free — create your own digital business card and share it instantly
          </p>
          <div className="flex gap-3">
            <a
              href="https://github.com/Katiechi/biobiz/releases/latest/download/app-release.apk"
              download
              className="flex-1 py-2.5 bg-[#C62828] hover:bg-[#AD1F1F] text-white rounded-xl font-semibold transition-colors text-sm text-center"
            >
              Download APK
            </a>
            <a
              href="/"
              className="flex-1 py-2.5 bg-white/10 hover:bg-white/15 text-white rounded-xl font-semibold transition-colors text-sm text-center"
            >
              Learn More
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}

function ContactIcon({ type }: { type: string }) {
  const icons: Record<string, string> = {
    email: '✉️',
    phone: '📞',
    address: '📍',
    link: '🔗',
    company_website: '🌐',
  };
  return <>{icons[type] || '•'}</>;
}

function SocialIcon({ platform }: { platform: string }) {
  const icons: Record<string, string> = {
    linkedin: 'in',
    instagram: 'IG',
    x: '𝕏',
    facebook: 'f',
    whatsapp: 'WA',
    telegram: 'TG',
    tiktok: 'TT',
    youtube: 'YT',
    github: 'GH',
  };
  return <>{icons[platform] || platform?.[0]?.toUpperCase() || '?'}</>;
}

function getContactLink(type: string, value: string): string {
  switch (type) {
    case 'email': return `mailto:${value}`;
    case 'phone': return `tel:${value}`;
    case 'link':
    case 'company_website': return value.startsWith('http') ? value : `https://${value}`;
    default: return '#';
  }
}

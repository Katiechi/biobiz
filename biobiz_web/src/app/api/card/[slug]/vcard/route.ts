import { supabase } from '@/lib/supabase';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params;

  // Fetch card
  const { data: card } = await supabase
    .from('cards')
    .select('*')
    .eq('slug', slug)
    .eq('is_active', true)
    .single();

  if (!card) {
    return NextResponse.json({ error: 'Card not found' }, { status: 404 });
  }

  // Fetch contact fields
  const { data: contactFields } = await supabase
    .from('card_contact_fields')
    .select('*')
    .eq('card_id', card.id)
    .order('sort_order');

  // Fetch social links
  const { data: socialLinks } = await supabase
    .from('card_social_links')
    .select('*')
    .eq('card_id', card.id)
    .order('sort_order');

  // Track save_contact event
  supabase.from('card_events').insert({
    card_id: card.id,
    event_type: 'save_contact',
  });

  // Generate vCard
  const vcard = generateVCard(card, contactFields || [], socialLinks || []);
  const name = `${card.first_name || ''} ${card.last_name || ''}`.trim() || 'contact';

  return new NextResponse(vcard, {
    headers: {
      'Content-Type': 'text/vcard; charset=utf-8',
      'Content-Disposition': `attachment; filename="${name}.vcf"`,
    },
  });
}

function generateVCard(
  card: Record<string, unknown>,
  contactFields: Record<string, unknown>[],
  socialLinks: Record<string, unknown>[]
): string {
  const lines: string[] = [];

  lines.push('BEGIN:VCARD');
  lines.push('VERSION:3.0');

  const firstName = (card.first_name as string) || '';
  const lastName = (card.last_name as string) || '';
  const middleName = (card.middle_name as string) || '';
  const prefix = (card.prefix as string) || '';
  const suffix = (card.suffix as string) || '';

  lines.push(`N:${lastName};${firstName};${middleName};${prefix};${suffix}`);
  const fullName = [prefix, firstName, middleName, lastName, suffix]
    .filter(Boolean)
    .join(' ');
  lines.push(`FN:${fullName}`);

  if (card.company) {
    const dept = card.department ? `;${card.department}` : '';
    lines.push(`ORG:${card.company}${dept}`);
  }

  if (card.job_title) lines.push(`TITLE:${card.job_title}`);
  if (card.headline) lines.push(`NOTE:${card.headline}`);
  if (card.company_website) lines.push(`URL:${card.company_website}`);
  if (card.profile_image_url) lines.push(`PHOTO;VALUE=uri:${card.profile_image_url}`);

  for (const field of contactFields) {
    const type = field.field_type as string;
    const value = field.value as string;
    const label = ((field.label as string) || 'WORK').toUpperCase();

    switch (type) {
      case 'email':
        lines.push(`EMAIL;TYPE=${label}:${value}`);
        break;
      case 'phone':
        lines.push(`TEL;TYPE=${label}:${value}`);
        break;
      case 'address':
        lines.push(`ADR;TYPE=${label}:;;${value}`);
        break;
      case 'link':
      case 'company_website':
        lines.push(`URL;TYPE=${label}:${value}`);
        break;
    }
  }

  for (const link of socialLinks) {
    lines.push(`X-SOCIALPROFILE;TYPE=${link.platform}:${link.url}`);
  }

  lines.push('END:VCARD');
  return lines.join('\r\n');
}

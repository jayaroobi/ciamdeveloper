"""Patch EDCC report references section with proper referential documents."""
from docx import Document
from docx.shared import Pt, RGBColor, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
from pathlib import Path

OUT = Path('/workspace/EDCC_Complete_Report.docx')
doc = Document(str(OUT))

def shade(elem, color):
    pPr = elem._p.get_or_add_pPr()
    sh = OxmlElement('w:shd')
    sh.set(qn('w:fill'), color)
    pPr.append(sh)

def tbar(text, dark=True):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(text)
    r.bold = True
    r.font.size = Pt(14 if dark else 11)
    r.font.color.rgb = RGBColor(255, 255, 255)
    shade(p, '1A6B7C' if dark else '3D9EB5')
    p.paragraph_format.space_after = Pt(0)

def sec(text):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.bold = True
    r.font.size = Pt(11)
    r.font.color.rgb = RGBColor(26, 107, 124)
    shade(p, 'D4EFF5')

def body(text, size=10.5):
    p = doc.add_paragraph(text)
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    for r in p.runs:
        r.font.size = Pt(size)

def ref_item(num, text):
    p = doc.add_paragraph(f'{num}. {text}')
    for r in p.runs:
        r.font.size = Pt(10)

# Find start of References page and remove trailing paragraphs
paras = doc.paragraphs
start = None
for i, p in enumerate(paras):
    if p.text.strip() == 'References':
        start = i
        break

if start is not None:
    # Remove trailing content but keep section properties (sectPr)
    body_el = doc.element.body
    children = list(body_el)
    start_el = doc.paragraphs[start]._element
    start_idx = children.index(start_el)
    for el in children[start_idx:]:
        if el.tag.endswith('sectPr'):
            continue
        body_el.remove(el)

# Add updated references section
tbar('References and Appendices')
tbar('Primary Data Sources and Referential Documents', dark=False)

body(
    'Note: All analysis, calculations, tables, figures, and conclusions in this report are based '
    'exclusively on the end-term assessment data (Tables 1, 2, and 3) and the additional information '
    'provided with the question paper. The referential documents listed below have been consulted for '
    'report structure, background context, and formatting guidance only. No statistics or data from '
    'external sources have been used in the analysis.',
    size=10,
)

sec('A. Primary Data Sources (Used for Analysis)')
primary = [
    'Energy Development and Conservation Council (EDCC). (2026). Table 1: Sector-wise Electricity Consumption (Billion Units), 2022–2025. End-Term Assessment Data.',
    'Energy Development and Conservation Council (EDCC). (2026). Table 2: Electricity Demand and Supply (Billion Units), 2022–2025. End-Term Assessment Data.',
    'Energy Development and Conservation Council (EDCC). (2026). Table 3: Renewable Energy and Transmission Losses, 2022–2025. End-Term Assessment Data.',
    'Energy Development and Conservation Council (EDCC). (2026). Additional Information provided with the End-Term Question Paper.',
]
for i, r in enumerate(primary, 1):
    ref_item(i, r)

sec('B. Referential Documents (Background and Report Format)')
referential = [
    'Central Electricity Authority. (2024). Load Generation Balance Report 2024-25. Ministry of Power, Government of India.',
    'Press Information Bureau. (2025). India\'s Energy Landscape: Powering Growth with Sustainable Energy. Government of India.',
    'Ministry of Statistics and Programme Implementation. (2025). Energy Statistics India 2025. Government of India.',
    'Bureau of Energy Efficiency. (2024). National Mission for Enhanced Energy Efficiency — Annual Report. Ministry of Power, Government of India.',
    'Government of India. (2003). The Electricity Act, 2003. Ministry of Power.',
    'Government of India. (2022). Revamped Distribution Sector Scheme (RDSS) — Guidelines. Ministry of Power.',
    'Course Material: Business Communication — Report Writing and Analytical Report Structure (Previous semester study documents).',
    'Energy Development and Conservation Council (EDCC). (2025). Earlier Council Briefing Documents on Electricity Consumption Trends.',
]
for i, r in enumerate(referential, 1):
    ref_item(i, r)

sec('Appendix: Calculations from End-Term Data Only')
calcs = [
    ('Agriculture growth (2022–2025)', '(98.45 − 83.30) / 83.30 × 100 = 18.2%'),
    ('Industrial growth (2022–2025)', '(33.65 − 23.48) / 23.48 × 100 = 43.3%'),
    ('Domestic growth (2022–2025)', '(71.25 − 58.44) / 58.44 × 100 = 21.9%'),
    ('Combined consumption growth', '(203.35 − 165.22) / 165.22 × 100 = 23.1%'),
    ('National demand growth', '(221 − 182) / 182 × 100 = 21.4%'),
    ('Demand–supply gap (2025)', '221 − 212 = 9 BU (4.1% of demand)'),
    ('Renewable energy share change', '35% − 24% = +11 percentage points'),
    ('T&D losses change', '18% − 15% = −3 percentage points'),
]
t = doc.add_table(rows=1 + len(calcs), cols=2)
t.style = 'Table Grid'
t.rows[0].cells[0].text = 'Calculation'
t.rows[0].cells[1].text = 'Result'
for ri, (a, b) in enumerate(calcs):
    t.rows[ri + 1].cells[0].text = a
    t.rows[ri + 1].cells[1].text = b

p = doc.add_paragraph('Page 10 | End of Report')
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
for r in p.runs:
    r.font.size = Pt(8)
    r.italic = True

doc.save(str(OUT))
print('References updated in', OUT)

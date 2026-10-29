"""
REPORT GENERATION COMPONENT: GENERATE TABLES
Formats processed summary catalogs into clean Markdown and LaTeX text matrices.
"""

def generate_manuscript_table_1_schema():
    """Generates the primary baseline parameter configuration matrix file (Table 1 text format)."""
    print("Generating formatted text files for Manuscript Table 1 database...")
    
    table_content = """| Symbol | Parameter Name | Baseline Value | Units | Provenance / Literature Reference Source |

| :--- | :--- | :--- | :--- | :--- |
| **HR** | Heart Rate | 75 | beats/min | Guyton & Hall Textbook of Medical Physiology (2021) |
| **Emax** | Maximum Ventricular Elastance | 2.0 | mmHg/mL | Suga & Sagawa Circ Res (1974) |
| **Emin** | Minimum Ventricular Elastance | 0.06 | mmHg/mL | Heldt et al. (2014) |
| **V0** | Unstressed Ventricular Volume | 10 | mL | Shi & Korakianitis Artif Organs (2006) |
| **Rsys** | Systemic Vascular Resistance | 1.0 | mmHg*s/mL | Chemla et al. Am J Physiol Heart Circ Physiol (2003) |
| **Ca** | Total Systemic Arterial Compliance | 1.5 | mL/mmHg | Yin & Liu Vascular Dynamics NATO ASI Series (1989) |
| **Cv** | Systemic Venous Compliance | 100 | mL/mmHg | Guyton & Hall Textbook of Medical Physiology (2021) |
"""
    
    output_path = "figures_output/Table_1_Baseline_Parameters.md"
    with open(output_path, "w") as f:
        f.write(table_content)
        
    print(f"  -> Table 1 text documentation generated successfully at: {output_path}")

if __name__ == "__main__":
    generate_manuscript_table_1_schema()

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
import warnings
from datetime import datetime

warnings.filterwarnings('ignore')

# Set visualization style
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette("husl")

print(f"Report Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

# =============================================================================
# Part 1: Data Retrieval from WRDS Compustat
# =============================================================================

def get_compustat_data(tickers, start_year, end_year):
    """
    Retrieve financial data from WRDS Compustat database.
    Uses the Fundamentals Annual (funda) table.
    
    Key Compustat Fields:
    - tic: Ticker Symbol
    - fyear: Fiscal Year
    - datafmt: Data Format (STD = Standard, SUMM_STD = Summary Standard)
    - at: Assets - Total
    - lt: Liabilities - Total
    - ceq: Common Equity - Total
    - act: Current Assets - Total
    - lct: Current Liabilities - Total
    - invt: Inventories - Total
    - rect: Receivables - Total
    - sale: Sales/Turnover (Revenue)
    - cogs: Cost of Goods Sold
    - xsga: Selling, General & Administrative Expense
    - ni: Net Income
    """
    
    try:
        import wrds
    except ImportError:
        print("Error: wrds package not installed. Run: pip install wrds")
        return None, None

    # Connect to WRDS
    print("Connecting to WRDS database...")
    db = wrds.Connection()
    
    # Build ticker condition for SQL query
    ticker_str = "', '".join(tickers)
    
    # SQL query with datafmt field included for deduplication
    sql = f"""
    SELECT 
        tic,
        datadate,
        fyear,
        datafmt,
        at,
        lt,
        ceq,
        act,
        lct,
        invt,
        rect,
        sale,
        cogs,
        xsga,
        ni
    FROM comp.funda
    WHERE tic IN ('{ticker_str}')
        AND fyear BETWEEN {start_year} AND {end_year}
        AND consol = 'C'
        AND popsrc = 'D'
    ORDER BY tic, fyear, datadate DESC
    """
    
    print(f"Querying Compustat database...")
    print(f"Tickers: {tickers}")
    print(f"Year Range: {start_year} - {end_year}")
    
    try:
        df_raw = db.raw_sql(sql, date_cols=['datadate'])
       
        db.close()
        print(f"Successfully retrieved {len(df_raw)} records. Database connection closed.")
       
        found_tickers = df_raw['tic'].unique()
        print(f"Found data for: {list(found_tickers)}")
      
        missing = [t for t in tickers if t not in found_tickers]
        if missing:
            print(f"WARNING: No data found for: {missing}")
        
    except Exception as e:
        print(f"Query failed: {e}")
        print("Rolling back transaction...")
        db.rollback()
        db.close()
        return None, None
   
    if len(df_raw) == 0:
        print("ERROR: No data retrieved for any ticker.")
        return None, None
   
    df_balance, df_income = process_compustat_data(df_raw, tickers)
    
    return df_balance, df_income


def process_compustat_data(df_raw, tickers):
    """
    Process raw Compustat data into standardized balance sheet and income statement formats.
    Compustat data is reported in millions USD.
    
    KEY FIX: Prioritizes STD format over SUMM_STD to avoid missing liability data.
    """
   
    company_mapping = {
        'WMT': {'name': 'Walmart', 'industry': 'Retail - General Merchandise'},
        'COST': {'name': 'Costco', 'industry': 'Retail - Warehouse Club'},
        'KR': {'name': 'Kroger', 'industry': 'Retail - Supermarket'},
    }
   
    df_raw['Year'] = pd.to_datetime(df_raw['datadate']).dt.year
  
    df_raw['Company'] = df_raw['tic'].map(
        lambda x: company_mapping.get(x, {}).get('name', x)
    )
    df_raw['Ticker'] = df_raw['tic']
   
    numeric_cols = ['at', 'lt', 'ceq', 'act', 'lct', 'invt', 'rect', 
                    'sale', 'cogs', 'xsga', 'ni']
    
    for col in numeric_cols:
        df_raw[col] = pd.to_numeric(df_raw[col], errors='coerce')
    
    # ===== KEY FIX: Prioritize STD format over SUMM_STD =====
   
    if 'datafmt' in df_raw.columns:
        df_raw['data_priority'] = df_raw['datafmt'].map({'STD': 1, 'SUMM_STD': 2}).fillna(3)
    else:
        df_raw['data_priority'] = 1
   
    key_cols = ['at', 'lt', 'ceq', 'sale', 'ni']
    df_raw['completeness'] = df_raw[key_cols].notna().sum(axis=1)
   
    df_raw = df_raw.sort_values(
        ['Ticker', 'Year', 'data_priority', 'completeness', 'datadate'],
        ascending=[True, True, True, False, False]
    )
  
    df_raw = df_raw.drop_duplicates(subset=['Ticker', 'Year'], keep='first')
   
    df_raw = df_raw.drop(columns=['data_priority', 'completeness'], errors='ignore')
   
    print("\nRecords kept after deduplication:")
    for tic in df_raw['Ticker'].unique():
        subset = df_raw[df_raw['Ticker'] == tic][['Ticker', 'Year', 'datafmt', 'sale', 'lt', 'ni']]
        print(f"\n{company_mapping.get(tic, {}).get('name', tic)} ({tic}):")
        print(subset.to_string(index=False))
    
    # Unit conversion: millions to billions
    unit_scale = 1000
    
    # Build Balance Sheet
    df_balance = pd.DataFrame({
        'Ticker': df_raw['Ticker'],
        'Company': df_raw['Company'],
        'Year': df_raw['Year'],
        'Total Assets': df_raw['at'] / unit_scale,
        'Total Liabilities': df_raw['lt'] / unit_scale,
        'Total Equity': df_raw['ceq'] / unit_scale,
        'Current Assets': df_raw['act'] / unit_scale,
        'Current Liabilities': df_raw['lct'] / unit_scale,
        'Inventory': df_raw['invt'] / unit_scale,
        'Accounts Receivable': df_raw['rect'] / unit_scale
    })
    
    # Build Income Statement
    df_income = pd.DataFrame({
        'Ticker': df_raw['Ticker'],
        'Company': df_raw['Company'],
        'Year': df_raw['Year'],
        'Revenue': df_raw['sale'] / unit_scale,
        'COGS': df_raw['cogs'] / unit_scale,
        'SG&A Expense': df_raw['xsga'] / unit_scale,
        'Net Income': df_raw['ni'] / unit_scale
    })
    
    return df_balance, df_income


# =============================================================================
# Part 2: Financial Ratio Calculation Engine
# =============================================================================

def calculate_financial_ratios(df_balance, df_income):
    """
    Calculate key financial ratios across four dimensions:
    1. Profitability
    2. Solvency
    3. Efficiency
    4. Growth
    """
    # Merge balance sheet and income statement
    df = pd.merge(df_balance, df_income, on=['Ticker', 'Company', 'Year'])
    
    # ===== 1. Profitability Ratios =====
    df['Gross Margin (%)'] = (df['Revenue'] - df['COGS']) / df['Revenue'] * 100
    df['Net Margin (%)'] = df['Net Income'] / df['Revenue'] * 100
    df['ROA (%)'] = df['Net Income'] / df['Total Assets'] * 100
    df['ROE (%)'] = df['Net Income'] / df['Total Equity'] * 100
    
    # ===== 2. Solvency Ratios =====
    df['Current Ratio'] = df['Current Assets'] / df['Current Liabilities']
    df['Quick Ratio'] = (df['Current Assets'] - df['Inventory']) / df['Current Liabilities']
    df['Debt-to-Assets (%)'] = df['Total Liabilities'] / df['Total Assets'] * 100
    
    # ===== 3. Efficiency Ratios =====
    df['Inventory Turnover'] = df['COGS'] / df['Inventory']
    df['Receivables Turnover'] = df['Revenue'] / df['Accounts Receivable']
    df['Asset Turnover'] = df['Revenue'] / df['Total Assets']
    
    # ===== 4. Growth Ratios =====
    df_sorted = df.sort_values(['Ticker', 'Year'])
    df['Revenue Growth YoY (%)'] = df_sorted.groupby('Ticker')['Revenue'].pct_change() * 100
    df['Net Income Growth YoY (%)'] = df_sorted.groupby('Ticker')['Net Income'].pct_change() * 100
    
    return df


# =============================================================================
# Part 3: Visualization Module
# =============================================================================

def plot_profitability_comparison(df, year):
    """Generate profitability comparison bar chart for a given year."""
    df_year = df[df['Year'] == year].copy()
    
    if df_year.empty:
        fig, ax = plt.subplots(figsize=(8, 4))
        ax.text(0.5, 0.5, f'No Data Available for {year}', 
                ha='center', va='center', fontsize=14)
        return fig
    
    fig, axes = plt.subplots(1, 3, figsize=(14, 4))
    
    metrics = ['Gross Margin (%)', 'Net Margin (%)', 'ROE (%)']
    titles = ['Gross Margin', 'Net Margin', 'Return on Equity (ROE)']
    colors = ['#2E86AB', '#A23B72', '#F18F01']
    
    for i, (metric, title) in enumerate(zip(metrics, titles)):
        if metric in df_year.columns:
            df_sorted = df_year.sort_values(metric, ascending=False)
            bars = axes[i].bar(df_sorted['Company'], df_sorted[metric], 
                              color=colors[i % len(colors)], alpha=0.8)
            axes[i].set_title(title, fontsize=14, fontweight='bold')
            axes[i].set_ylabel('%', fontsize=11)
            axes[i].tick_params(axis='x', rotation=30)
            
            for bar, val in zip(bars, df_sorted[metric]):
                if not np.isnan(val):
                    axes[i].text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5,
                                f'{val:.1f}%', ha='center', fontsize=10)
    
    plt.suptitle(f'{year} Profitability Comparison', fontsize=16, fontweight='bold')
    plt.tight_layout()
    return fig


def plot_radar_chart(df, year):
    """Generate multi-dimensional radar chart for a given year."""
    df_year = df[df['Year'] == year].copy()
    
    if df_year.empty:
        fig, ax = plt.subplots(figsize=(8, 4))
        ax.text(0.5, 0.5, f'No Data Available for {year}', 
                ha='center', va='center', fontsize=14)
        return fig
    
    metrics = ['Gross Margin (%)', 'Net Margin (%)', 'ROE (%)', 'Current Ratio', 'Inventory Turnover']
    metric_labels = ['Gross Margin', 'Net Margin', 'ROE', 'Current Ratio', 'Inventory Turnover']
    
    # Normalize
    df_norm = df_year.copy()
    for m in metrics:
        if m in df_norm.columns and df_norm[m].notna().any():
            max_v = df_norm[m].max()
            min_v = df_norm[m].min()
            if max_v > min_v:
                df_norm[f'{m}_norm'] = (df_norm[m] - min_v) / (max_v - min_v)
            else:
                df_norm[f'{m}_norm'] = 0.5
        else:
            df_norm[f'{m}_norm'] = 0.5
    
    N = len(metrics)
    angles = [n / N * 2 * np.pi for n in range(N)]
    angles += angles[:1]
    
    fig, ax = plt.subplots(figsize=(10, 8), subplot_kw=dict(projection='polar'))
    
    colors = ['#2E86AB', '#A23B72', '#F18F01']
    
    for i, company in enumerate(df_norm['Company'].unique()):
        values = []
        for m in metrics:
            val = df_norm[df_norm['Company'] == company][f'{m}_norm'].values
            values.append(val[0] if len(val) > 0 else 0)
        values += values[:1]
        
        ax.plot(angles, values, 'o-', linewidth=2, label=company, color=colors[i % len(colors)])
        ax.fill(angles, values, alpha=0.15, color=colors[i % len(colors)])
    
    ax.set_xticks(angles[:-1])
    ax.set_xticklabels(metric_labels, fontsize=11)
    ax.set_ylim(0, 1)
    ax.set_title(f'{year} Multi-Dimensional Financial Comparison', fontsize=16, fontweight='bold', pad=20)
    ax.legend(loc='upper right', bbox_to_anchor=(1.3, 1.0))
    ax.grid(True)
    
    plt.tight_layout()
    return fig


def plot_trend(df, company_name):
    """Generate trend analysis charts for a single company."""
    df_company = df[df['Company'] == company_name].sort_values('Year')
    
    if df_company.empty:
        fig, ax = plt.subplots(figsize=(8, 4))
        ax.text(0.5, 0.5, f'No Data Available for {company_name}', 
                ha='center', va='center', fontsize=14)
        return fig
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    # 1. Profitability Trends
    ax1 = axes[0, 0]
    if 'Gross Margin (%)' in df_company.columns:
        ax1.plot(df_company['Year'], df_company['Gross Margin (%)'], 'o-', 
                color='#2E86AB', linewidth=2, markersize=8, label='Gross Margin')
    if 'Net Margin (%)' in df_company.columns:
        ax1.plot(df_company['Year'], df_company['Net Margin (%)'], 's-', 
                color='#A23B72', linewidth=2, markersize=8, label='Net Margin')
    if 'ROE (%)' in df_company.columns:
        ax1.plot(df_company['Year'], df_company['ROE (%)'], '^-', 
                color='#F18F01', linewidth=2, markersize=8, label='ROE')
    ax1.set_title('Profitability Trends', fontsize=13, fontweight='bold')
    ax1.set_ylabel('%')
    ax1.legend(loc='best')
    ax1.grid(True, alpha=0.3)
    
    # 2. Solvency Trends
    ax2 = axes[0, 1]
    if 'Current Ratio' in df_company.columns:
        ax2.plot(df_company['Year'], df_company['Current Ratio'], 'o-', 
                color='#6A994E', linewidth=2, markersize=8, label='Current Ratio')
    ax2.axhline(y=1.5, color='red', linestyle='--', alpha=0.5, label='Warning Threshold')
    ax2.set_title('Solvency Trends', fontsize=13, fontweight='bold')
    ax2.set_ylabel('Ratio')
    ax2.legend(loc='best')
    ax2.grid(True, alpha=0.3)
    
    # 3. Efficiency Trends
    ax3 = axes[1, 0]
    if 'Inventory Turnover' in df_company.columns:
        ax3.plot(df_company['Year'], df_company['Inventory Turnover'], 'o-', 
                color='#C73E1D', linewidth=2, markersize=8, label='Inventory Turnover')
    if 'Asset Turnover' in df_company.columns:
        ax3.plot(df_company['Year'], df_company['Asset Turnover'], 's-', 
                color='#3A7CA5', linewidth=2, markersize=8, label='Asset Turnover')
    ax3.set_title('Efficiency Trends', fontsize=13, fontweight='bold')
    ax3.set_ylabel('Times')
    ax3.legend(loc='best')
    ax3.grid(True, alpha=0.3)
    
    # 4. Growth Trends
    ax4 = axes[1, 1]
    if len(df_company) > 1:
        years = df_company['Year'].values[1:]
        
        revenue_growth = df_company['Revenue Growth YoY (%)'].values[1:] if 'Revenue Growth YoY (%)' in df_company.columns else np.zeros(len(years))
        profit_growth = df_company['Net Income Growth YoY (%)'].values[1:] if 'Net Income Growth YoY (%)' in df_company.columns else np.zeros(len(years))
        
        x = np.arange(len(years))
        width = 0.35
        ax4.bar(x - width/2, revenue_growth, width, label='Revenue Growth YoY', color='#2E86AB')
        ax4.bar(x + width/2, profit_growth, width, label='Net Income Growth YoY', color='#A23B72')
        ax4.axhline(y=0, color='black', linestyle='-', alpha=0.5)
        ax4.set_xticks(x)
        ax4.set_xticklabels(years)
    
    ax4.set_title('Growth Trends (Year-over-Year)', fontsize=13, fontweight='bold')
    ax4.set_ylabel('%')
    ax4.legend(loc='best')
    ax4.grid(True, alpha=0.3)
    
    plt.suptitle(f'{company_name} Financial Trend Analysis', fontsize=16, fontweight='bold')
    plt.tight_layout()
    return fig


# =============================================================================
# Part 4: Main Execution
# =============================================================================

if __name__ == "__main__":
    
    print("=" * 80)
    print("U.S. Retail Giants Financial Health Analyzer")
    print("Data Source: WRDS Compustat North America")
    print("=" * 80)
    
    # Analysis Parameters
    TICKERS = ['WMT', 'COST', 'KR']  # Walmart, Costco, Kroger
    START_YEAR = 2020
    END_YEAR = 2024
    
    # Step 1: Retrieve data from WRDS
    df_balance, df_income = get_compustat_data(TICKERS, START_YEAR, END_YEAR)
    
    if df_balance is None or df_income is None:
        print("ERROR: Data retrieval failed. Program terminated.")
        exit(1)
    
    # Display which companies were found
    companies_found = df_balance['Company'].unique()
    print(f"\nCompanies successfully retrieved: {list(companies_found)}")
    
    # Display raw data preview
    print("\n" + "=" * 80)
    print("Balance Sheet Preview (in Billions USD)")
    print("=" * 80)
    display_cols_bs = ['Company', 'Year', 'Total Assets', 'Total Liabilities', 'Total Equity']
    print(df_balance[display_cols_bs].head(15).round(2).to_string())
    
    print("\n" + "=" * 80)
    print("Income Statement Preview (in Billions USD)")
    print("=" * 80)
    display_cols_is = ['Company', 'Year', 'Revenue', 'COGS', 'Net Income']
    print(df_income[display_cols_is].head(15).round(2).to_string())
    
    # Step 2: Calculate financial ratios
    df_ratios = calculate_financial_ratios(df_balance, df_income)
    
    latest_year = 2024
    
    print("\n" + "=" * 80)
    print(f"Key Financial Ratios - {latest_year}")
    print("=" * 80)
    
    # Display key ratios
    display_cols = ['Company', 'Gross Margin (%)', 'Net Margin (%)', 'ROE (%)', 
                    'Current Ratio', 'Debt-to-Assets (%)', 'Inventory Turnover', 
                    'Revenue Growth YoY (%)']
    
    df_display = df_ratios[df_ratios['Year'] == latest_year][display_cols].round(2)
    print(df_display.to_string(index=False))
    
    # Step 3: Generate visualizations and save images
    
    os.makedirs('images', exist_ok=True)
    print("\n✅ images folder ready")
    
    company_file_map = {
        'Walmart': 'trend_wmt',
        'Costco': 'trend_cost',
        'Kroger': 'trend_kr'
    }
    
    saved_files = []
    
    # Figure 1: Profitability Comparison
    print("\n[1/5] Saving Profitability Comparison...")
    fig1 = plot_profitability_comparison(df_ratios, latest_year)
    fig1.savefig('images/profitability_comparison.png', dpi=300, bbox_inches='tight')
    plt.show()
    saved_files.append('images/profitability_comparison.png')
    print("✅ Saved: images/profitability_comparison.png")
    
    # Figure 2: Radar Chart
    print("\n[2/5] Saving Radar Chart...")
    fig2 = plot_radar_chart(df_ratios, latest_year)
    fig2.savefig('images/radar_chart.png', dpi=300, bbox_inches='tight')
    plt.show()
    saved_files.append('images/radar_chart.png')
    print("✅ Saved: images/radar_chart.png")
    
    # Figures 3-5: Trend Analysis for each company
    for i, company in enumerate(companies_found):
        file_key = company_file_map.get(company, company.lower().replace(' ', '_'))
        filename = f'images/{file_key}.png'
        
        print(f"\n[{i+3}/5] Saving {company} Trend Analysis...")
        fig = plot_trend(df_ratios, company)
        fig.savefig(filename, dpi=300, bbox_inches='tight')
        plt.show()
        saved_files.append(filename)
        print(f"✅ Saved: {filename}")
    
    # Confirmation
    print("\n" + "=" * 50)
    print("📁 All figures saved to 'images/' folder:")
    for f in saved_files:
        print(f"  ✅ {f}")
    print("=" * 50)
    
    # Step 4: Summary
    print("\n" + "=" * 80)
    print("Analysis Complete!")
    print(f"Report Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)
    
    print("\n" + "=" * 80)
    print("Data Provenance")
    print("=" * 80)
    print(f"Source: WRDS - Compustat North America, Fundamentals Annual")
    print(f"Companies Analyzed: {', '.join(companies_found)}")
    print(f"Period: Fiscal Years {START_YEAR} - {END_YEAR}")
    print(f"Data Retrieved: {datetime.now().strftime('%Y-%m-%d')}")
    print("=" * 80)

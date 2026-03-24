import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# =========================================
# 1. LOAD DATA
# =========================================
df = pd.read_csv('../0.csv',sep=";")

print("Data loaded. Shape:", df.shape)

# =========================================
# 2. SELECT RELEVANT COLUMNS
# =========================================
cols = ['wind_speed_3_avg', 'power_29_avg', 'power_30_avg']
df = df[cols].dropna()

# =========================================
# 3. CORRELATION (to choose correct power)
# =========================================
corr = df.corr()
print("\nCorrelation matrix:\n", corr)

# Choose power_29 (based on higher correlation)
wind = df['wind_speed_3_avg']
power = df['power_29_avg']

# =========================================
# 4. BASIC CLEANING (Region 2)
# =========================================
df_clean = df[
    (df['wind_speed_3_avg'] > 4) &
    (df['wind_speed_3_avg'] < 10) &
    (df['power_29_avg'] > 0)
].copy()

print("Clean data size:", df_clean.shape)

# =========================================
# 5. CREATE POWER CURVE (BINNING)
# =========================================
bins = np.arange(4, 10, 0.5)
df_clean['bin'] = pd.cut(df_clean['wind_speed_3_avg'], bins)

power_curve = df_clean.groupby('bin').agg({
    'wind_speed_3_avg': 'mean',
    'power_29_avg': 'mean'
}).dropna()

# =========================================
# 6. EXTRACT ARRAYS
# =========================================
V_real = power_curve['wind_speed_3_avg'].values
P_real = power_curve['power_29_avg'].values

# =========================================
# 7. PLOT RESULTS
# =========================================
plt.figure()

# Raw data (optional, shows noise)
plt.scatter(df_clean['wind_speed_3_avg'],
            df_clean['power_29_avg'],
            s=5, alpha=0.2, label='Raw SCADA')

# Clean power curve
plt.scatter(V_real, P_real, color='red', label='Binned Power Curve')

plt.xlabel('Wind speed (m/s)')
plt.ylabel('Power (kW)')
plt.title('SCADA Wind Turbine Power Curve (Region 2)')
plt.legend()
plt.grid()

plt.show()

# =========================================
# 8. PRINT FINAL DATA (for validation)
# =========================================
print("\nWind speeds (V_real):\n", V_real)
print("\nPower values (P_real):\n", P_real)
export_df = pd.DataFrame({
    'wind_speed': V_real,
    'power': P_real
})

export_df.to_csv('scada_power_curve.csv', index=False)

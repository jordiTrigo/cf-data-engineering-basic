#%%
import pandas as pd

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
pd.set_option('display.max_colwidth', None)

df = pd.read_json('./data/catalunya_defunciones_por_provincia.json')
df.head(20)
df.info()
# %%


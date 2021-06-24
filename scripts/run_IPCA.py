import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
from sklearn.decomposition import IncrementalPCA
from joblib import dump, load





# In[80]:


chunk_size = 100

all_baits = pd.read_table('../mounted-data/index_tab.txt', header=None)
common_baits = pd.read_table('../intermediate_files/baits_common.bed', header=None)

all_baits['ID'] = all_baits[0].astype(str) + ':' + all_baits[1].astype(str) + ':' + all_baits[2].astype(str)
common_baits['ID'] = common_baits[0].astype(str) + ':' + common_baits[1].astype(str) + ':' + common_baits[2].astype(str)

all_files = [f'../PCA_logRratio_chunk/PCA_logR_ratio_chunk_{i}.csv.gz' for i in range(1, 6)]

keep_all = all_baits[0] < 23
keep_common = np.logical_and(keep_all, all_baits.ID.isin(common_baits.ID))
keep_rare = np.logical_and(keep_all, ~keep_common)
print(keep_all.sum())
print(keep_rare.sum())
print(keep_common.sum())


# In[81]:



ipca_common = IncrementalPCA(n_components=50, whiten=True)
ipca_rare = IncrementalPCA(n_components=50, whiten=True)
ipca_all = IncrementalPCA(n_components=50, whiten=True)

for fpath in all_files:
    print(fpath)
    x = np.loadtxt(fpath, delimiter=',', dtype=np.float32)
    n_chunk = np.int(np.ceil(x.shape[0] / 100))
    for chunk in np.array_split(x, n_chunk):
        print(chunk.shape)
        ipca_common.partial_fit(chunk[:,keep_common])
        ipca_rare.partial_fit(chunk[:,keep_rare])
        ipca_all.partial_fit(chunk[:, keep_all])


# In[82]:


dump(ipca_common, '../covar/IPCA.common.baits.v3.joblib') 
dump(ipca_rare, '../covar/IPCA.rare.baits.v3.joblib')
dump(ipca_all, '../covar/IPCA.all.baits.v3.joblib') 


# In[83]:




x = np.loadtxt('../PCA_logRratio_chunk/PCA_logR_ratio_chunk_1.csv.gz', delimiter=',', dtype=np.float32)
pc_common = ipca_common.transform(x[:,keep_common])
pc_rare = ipca_rare.transform(x[:,keep_rare])
pc_all = ipca_all.transform(x[:,keep_all])
for fpath in all_files[1:]:
    print(fpath)
    x = np.loadtxt(fpath, delimiter=',', dtype=np.float32)
    pc_common = np.r_[pc_common, ipca_common.transform(x[:,keep_common])]
    pc_rare = np.r_[pc_rare, ipca_rare.transform(x[:,keep_rare])]
    pc_all = np.r_[pc_all, ipca_all.transform(x[:,keep_all])]
    print(pc_all.shape)


# In[95]:


ipca_all.components_.shape


# In[84]:


covar = pd.read_table('../covar/covid_v2.5_covar_GT_pca20.tsv', index_col='platekey')
pc_common = pd.DataFrame(pc_common, columns=['cnv_common_PC' + str(i) for i in range(1, 51)], index=covar.index)
pc_rare = pd.DataFrame(pc_rare, columns=['cnv_rare_PC' + str(i) for i in range(1, 51)], index=covar.index)
pc_all = pd.DataFrame(pc_all, columns=['cnv_all_PC' + str(i) for i in range(1, 51)], index=covar.index)


# In[85]:


cnv_pcs = pd.concat([pc_common, pc_rare, pc_all], axis=1)
cnv_pcs.to_csv('../covar/IPCA.top50PCs.v3.csv')


# In[96]:


covar = pd.read_table('../covar/covid_v2.5_covar_GT_pca20.tsv', index_col='platekey')
covar = pd.concat([covar, cnv_pcs], axis=1)
meta = pd.read_table('../mounted-data/aggCOVID_V3_phenofile_9406_20210512.tsv', index_col='plate_key')
covar = pd.merge(covar, meta.loc[:,('ancestry_pred')], left_index=True, right_index=True)


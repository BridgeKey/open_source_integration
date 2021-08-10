#!/usr/bin/env python
# coding: utf-8

# In[7]:


def runPythonCode():
    "Output: MyOutPutKey"
    import swat
    import pandas
    from datetime import datetime

    s = swat.CAS('localhost', 5570, 'sasdemo', 'Orion123')
    fetch_opts = dict(maxrows=100000000, to=1000000)
    sas_iris = pandas.DataFrame(s.table.fetch(table={"caslib":"open_source_integration", "name":"iris"}, **fetch_opts)["Fetch"])

    cols = sas_iris.columns
    print(cols)
    cols = cols[1:5]
    sas_iris1 = sas_iris[cols]

    # now adding new column "total_values" to dataframe data.
    sas_iris["TotalValues"]=sas_iris1[cols].sum(axis=1)
    # here axis=1 means you are working in rows,
    # whereas axis=0 means you are working in columns.

    # add a current time variable
    x = datetime.now()
    sas_iris["Time"] = x.strftime("%m/%d/%Y %H:%M:%S")


    s.dropTable(name = "iris_from_python",
                caslib = "open_source_integration",
                quiet = "TRUE")
    s.upload_frame(sas_iris,
                    casout=dict(caslib = "open_source_integration",
                                name = "iris_from_python",
                                promote = 'true'))


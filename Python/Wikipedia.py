#!/usr/bin/env python
# coding: utf-8

# In[38]:


def runPythonCode():    
    "Output: MyOutPutKey"
    import wikipedia
    import pandas
    import swat
    from datetime import datetime

    s = swat.CAS('localhost', 5570, 'sasdemo', 'Orion123')
    fetch_opts = dict(maxrows=100000000, to=1000000)
    sas_iris = pandas.DataFrame(s.table.fetch(table={"caslib":"open_source_integration", "name":"iris"}, **fetch_opts)["Fetch"])

    test = pandas.DataFrame(sas_iris.Species.unique())

    summary_result = test.apply(lambda x : wikipedia.summary("Iris " + x, sentences=1), axis=1)

    def wiki_URL(x):
        page = wikipedia.page("Iris " + x)
        full = page.url
        result = full.replace('https://en.wikipedia.org/wiki/','')
        return(result)

    URL_result = test.apply(wiki_URL, axis=1)
    
    result = pandas.concat([test, summary_result, URL_result], axis = 1)
    result.columns = ["Species","Summary","URL"]

    new = sas_iris.set_index('Species').join(result.set_index('Species'))

    x = datetime.now()
    new["Time"] = x.strftime("%m/%d/%Y %H:%M:%S")
    new.reset_index(inplace=True)

    s.dropTable(name = "iris_from_python",
                caslib = "open_source_integration",
                quiet = "TRUE")
    s.upload_frame(new,
                    casout=dict(caslib = "open_source_integration",
                                name = "iris_from_python",
                                promote = 'true'))


# In[54]:


def wikiQuery(query = "Dandelion"):
    "Output: MyOutPutKey"
    import wikipedia
    import pandas
    import swat
    from datetime import datetime
    
    s = swat.CAS('localhost', 5570, 'sasdemo', 'Orion123')
    
    try:
        result = wikipedia.page(query)
        full_URL = result.url
        URL = full_URL.replace('https://en.wikipedia.org/wiki/','')
        Summary = wikipedia.summary(query, sentences = 1)
    except Exception:
        URL = "Search term overly ambiguous"
        Summary = "Search term overly ambiguous"
        
    
    d = {'Query': [query], 'Summary': [Summary], 'URL':[URL]}
    query_result = pandas.DataFrame(data=d)
    
    s.dropTable(name = "wikiSearch",
                caslib = "open_source_integration",
                quiet = "TRUE")
    s.upload_frame(query_result,
                    casout=dict(caslib = "open_source_integration",
                                name = "wikiSearch",
                                promote = 'true'))
    print(query + ": " + Summary)


# ```This code parse text Concference Calls (CC) to CSV Data Frame ```
# ```Code uses two files: 1) *.XLS file with a list of CC per file and 2) *.txt file, which was converted from pdf file ```
# ```Code use information from XLS file about type of Anaylist to parse CC in different ways ```

# using Pkg, Pkg.add("XLSX")

using PDFIO
using CSVFiles
using DataFrames
using CSV
using Gumbo
using Cascadia
using Dates
import Gumbo.text
using Statistics
using Test

confcalloutputfolder = "C:/Users/jasonjia/Dropbox/Projects/conference_call/output"
pdffolder = "01_download_cc/01.1_pdf_20210101_20220617"
xlsfolder = "01_download_cc/01.1_xls_20210101_20220617"
txtfolder = "02_process_cc/02.1_txt_20210101_20220617"
csvfolder = "02_process_cc/02.2_csv_20210101_20220617"
badlistfilepath = "02_process_cc/checks/BadList_20210101_20220617.csv"

``` read list of firm per pdf documents ```
function parseHtmlXlsToDf(filename)
    print(string("parseHtmlXlsToDf: ", " | "))
    try
        list_html_raw=read(filename,String)
        list_html = parsehtml(String(list_html_raw))
        dflist=DataFrame(PPV=String[],TOC=String[],Title=String[],Subtitle=String[],Date=Dates.Date[],Pages=Int[],Price=String[],Contributor=String[],
                Analyst=[],Language=[],Report=Int[],Collection=[])
        tr=eachmatch(sel"tr", list_html.root)
        nrow=size(tr)[1]-1
        for i=2:(nrow+1)
            td=eachmatch(sel"td", tr[i])
            date_row=Date(text(td[5][1]),"mm/dd/yy")
            date_row=Year(date_row)<Year(1900) ? date_row+Year(2000) : date_row
            row=[text(td[1][1]),text(td[2][1]),text(td[3][1]),text(td[4][1]),date_row,parse(Int,text(td[6][1])),text(td[7][1]),text(td[8][1]),text(td[9][1]),
                    text(td[11][1]),parse(Int,text(td[12][1])),text(td[13][1])]
            push!(dflist,row)
        end
        return  dflist
    catch e
        println(string(e)[1:50])
    end
end

``` get page from the document ```
function getPage(doc::Vector,page_n)
    print(string(page_n,"-"))
    try
        return doc[page_n]
    catch e
        println(string(e)[1:50])
    end
end

function getPage(doc,page_n)
    print(string(page_n,"--"))
    try
        page = pdDocGetPage(doc, page_n)
        io = IOBuffer()
        pdPageExtractText(io, page)
        page_str=String(take!(io))
    catch
        page_str=""
    end
end

``` get contents of the pdf documnet```
function getPageContents(doc)
    print(string("getPageContents", " | "))
    try
    i=1
    content=""
    while true
        try
            page=getPage(doc,i)
            findfirst("Table of Contents",page)[1]
            content=string(content," \n ",page)
            i+=1
        catch
            break
        end
    end
    return content, (i-1)
catch e
    println(string(e)[1:50])
end
end

``` get from the content the first page number of the CCall firm by name or by Rpt number```
``` we use report number, since the firm can have several report for a documents ```
function getFirmPageNumber(content,report_n::Int)
    println(".")
    print(string("getFirmPageNumber: ",report_n," | "))
    try
    l=findfirst(string(report_n),content)[end]
    e=findnext("-",content,l+70)[1]
    #return parse(Int,content[e-5:e-1])
    return parse(Int,content[e-4:e-1])
catch e
    return 1
end
end

``` 1st type of CCall```
function cutHeader(page,lastpage=false)
    # println("cutHeader")
    try
    if !isnothing(findfirst("PRELIMINARY",page))
        p=findfirst("PRELIMINARY",page)[end]
        l=findnext("\n\n",page,p+10)[end]
        return page[l+1:end]
    else
        l=findfirst("\n\n",page)[end]
        ll=0
        if lastpage
            if !isnothing(findfirst("\n\n",page[nextind(page,l+10):nextind(page,l+150)]))
                ll=l
                l=findfirst("\n\n",page[nextind(page,l+10):nextind(page,l+150)])[end]+10
            end
            return page[ll+l:end]
        else
            return page[l+1:end]
        end

    end
catch e
    println(string(e)[1:50])
end
end


function cutBottom(page)
    # println("cutBottom")
    page=replace(page,"\n\n\n\n\n"=>"\n")
    page=replace(page,"\n\n\n\n"=>"\n")
    page=replace(page,"\n\n\n"=>"\n\n")
    try
        if !isnothing(findfirst(r"\d{1,3}\n{0,}refinitiv streetevents \|",lowercase(page[prevind(page, lastindex(page),700):end])))
            l=findfirst(r"\d{1,3}\n{0,}refinitiv streetevents \|",lowercase(page[prevind(page, lastindex(page),700):end]))[1]
        # elseif !isnothing(findfirst(r"REFINITIV STREETEVENTS \|",uppercase(page[prevind(page, lastindex(page),700):end])))
        #    l=findfirst(r"REFINITIV STREETEVENTS \|",uppercase(page[prevind(page, lastindex(page),700):end]))[1]
        else
            l=0
        end
        return  page[1:prevind(page, lastindex(page),700-l+3)]
        #return page[1:end-700+l-3]
    catch e
        println("cutBottom_catch")
        println(string(e)[1:50])
            return page
    end
end

    # return page[1:l-1]

    function cutDisclaimer(page)
        try
        if !isnothing(findfirst("DISCLAIMER\n",page))
                l=findfirst("DISCLAIMER\n",page)[1]
        elseif  !isnothing(findfirst("DISCLAIMER:",page))
                l=findfirst("DISCLAIMER:",page)[1]
        elseif  !isnothing(findfirst("all products and services provided by fdfn",lowercase(page)))
                l=findfirst("all products and services provided by fdfn",lowercase(page))[1]
        else
                l=lastindex(page)+1
        end
        return page[1:l-1]
        catch e
            println(string(e)[1:50])
        end

    end


function getFirmCC_t3(doc,page_s,page_e)
    print(string("getFirmCC: ",page_s,", ",page_e, " | "))
    try
    call=""
    for i=page_s+1:page_e
        # println("page-",i)
        page=getPage(doc,i)
        if page!=""
            page=cutHeader(page,false)
            if length(page)<700
                break
            end
            page=cutBottom(page)

            # if IsTwoColumns(page)
            #    page=twoColumsToText(page)
            # end
            # if i==page_e
            #     page=cutDisclaimer(page)
            # end
            call=string(call," \n ",page)
        else
            break
        end
    end
    call=cutDisclaimer(call)
    return call
catch e
    println(string(e)[1:50])
    return ""
end
end

``` end 1st type ```

```given line, looking for a second conlumn start ```

function findColumn(line)
    println("findColumn")
    try
        if length(line)>0
            if length(line)>55
                if length(strip(line))<50
                    return (length(line)- length(strip(line))),(length(line)- length(strip(line))+1)
                 else
                    d=10
                     while isnothing(findfirst(" "^d,line[nextind(line,44):end]))
                         d=d-1
                     end
                     if d>2
                         sc=findfirst(" "^d,line[nextind(line,44):end])
                         return nextind(line,43+sc[1]), nextind(line,43+sc[end])
                     else
                         return lastindex(line) , 0
                     end
                end
             else
                 return lastindex(line) , 0
             end
         else
             return 0,0
         end
     catch e
        println(string(e)[1:50])
     end
end

# ``` Parse file```
function parseCalls(filename, pdffolder, xlsfolder, txtfolder, badlistfilepath)
    try
    #get list of CC
    dflist=parseHtmlXlsToDf("$xlsfolder/$filename.xls")
    #dflist=parseHtmlXlsToDf("XlsTest/$filename.xls")
    dflist[!,:Call].=""

    #doc = pdDocOpen("$filename.pdf")
    doc_pdf = pdDocOpen("$pdffolder/$filename.pdf")
    doc_text=String(read("$txtfolder/$filename.txt"))
    #doc_pdf = pdDocOpen("PdfTest/$filename.pdf")
    #doc_text=String(read("TxtTest/$filename.txt"))
    doc=split(doc_text,"\f")
    content, pn = getPageContents(doc_pdf)
    # row=dflist[50,:]
    if size(dflist)[1]!=1
        for row in eachrow(dflist)
            try
                #println(row.Title)
                firmname=row.Title
                analyst=row.Analyst
                report_number=row.Report
                page_size=row.Pages
                page_n=getFirmPageNumber(content,report_number)
                if page_n!=1
                        # call=getFirmCC_t1(doc_pdf,page_n,page_n+page_size-1)
                        call=getFirmCC_t3(doc,page_n,page_n+page_size-1)
                    row[:Call]=call
                else
                    global dfBadFile
                    push!(dfBadFile,[filename,row.Title])
                    CSV.write(badlistfilepath,dfBadFile)
                end
            catch e
                println("Row Error:-",e)
                row[:Call]=""
            end
        end
    else
        row=dflist[1,:]
        try
            #println(row.Title)
            analyst=row.Analyst
            page_size=row.Pages
            call=getFirmCC_t3(doc,1,page_size)
            row[:Call]=call
        catch e
            println("Row Error:-",e)
            row[:Call]=""
        end
    end
    pdDocClose(doc_pdf)
    return dflist
catch e
    println(e)
    try
        pdDocClose(doc_pdf)
    catch
    end
end
end

# ```parse all file from the currrent  ```
function main()
    files=readdir("$xlsfolder")
    # files=readdir("XlsTest")
    for file in files
        if file[end-2:end]=="xls"
            try
                filename=file[1:end-4]
                println("")
                println(file)
                @time dfCalls=parseCalls(filename, pdffolder, xlsfolder, txtfolder, badlistfilepath)
                CSV.write("$csvfolder/$filename.csv",dfCalls)
                #CSV.write("CsvTest/$filename.csv",dfCalls)
            catch e
                println(e)
            end
        end
    end
end


## START OF CODE
println("Start parsing CCs from pdf, txt and xls into csv")
global dfBadFile=DataFrame(filename=String[],Title=String[])


# Overall structure: -> main
try
    # Sixun's comment, N/A: cd("..//..//..//..//project//EC_Mercury//final_sup")
    cd(confcalloutputfolder)
    # cd("C:/Users/jasonjia/Dropbox/ConferenceCall/Misc/Trial2")
    @time main()
    CSV.write(badlistfilepath,dfBadFile)
    #CSV.write("BadListTest.csv",dfBadFile)
    try
        mkdir("Csv")
        #mkdir("CsvTest")
    catch errorcsv
    end
    # filename="20030311-20030314_1"
    # df=parseCalls(filename)
catch error
    println(error)
end
CSV.write(badlistfilepath,dfBadFile)
println("Finished parsing CCs from pdf, txt and xls into csv")

# @test

class CJson
{
    private dictionary JsonData; 

    //格式检查
    private bool BracketsCheack(string & in strJson)
    {
        if (strJson.Split("{").length() == strJson.Split("}").length())
            if (strJson.Split("[").length() == strJson.Split("]").length())
                return true; 
        return false; 
    }

    //分割元数据
    private array < string > SplitMeta(string & in strJson)
    {
        strJson = strJson.SubString(1, strJson.Length()-1); 
        return strJson.Split("},"); 
    }
    
    //解析数组
    private array < string > GetJsonDataArray (string & in strData)
    {
        strData = strData.Replace("[","").Replace("]","").Replace("],",""); 
        array < string > returnAry; 
        array < string > cacheAry = strData.Split(","); 
        for (uint i = 0; i < cacheAry.length(); i++)
        {
            if ( !cacheAry[i].IsEmpty())
                returnAry.insertLast(cacheAry[i].Replace("\"",""));
        }
        return returnAry;
    }

    //解析
    private dictionary dicJson(string&in strJson)
    {
        dictionary Json;

        string objName = strJson.SubString(0,strJson.FindFirstOf(" {")-1);
        objName = objName.Replace(":","").Replace( "\"", ""); 
        //JsonData里储存的名称

        //获得Object起始位置
        uint f = 0; 
        uint d = strJson.FindFirstOf("{"); 
        while (f < 2)
        {
            if (strJson.opIndex(d) == '\"')
                f++; 
            d--; 
        }
        //以第一个{分割的后半段
        string objJson = strJson.SubString(d, strJson.Length()); 

        //检查后半段是否还有{ {
        if (objJson.FindFirstOf("{") >= 0)
        {
            Json[objName] = dicJson(objJson); 
            //后半段嵌套
            objJson = objJson.SubString(0, objJson.FindFirstOf("{")-1); 
            //处理没有{的前半段
        }

        //Json数据处理
        array < string > aryJson = objJson.Split("\":");
        array<string> aryName,aryData;
        for(uint i = 0;i < aryJson.length();i++)
        {
            if(i % 2 == 0)
                aryName.insertLast(aryJson[i].Replace("\"","")); 
            else
                aryData.insertLast(aryJson[i]); 
        }

        //Json类型判断
        for (uint j = 0; j < aryName.length(); j++)
        {
            if (aryData[j].FindFirstOf("[") >= 0)
                Json[aryName[j]] = GetJsonDataArray(aryData[j]); 
            else {
                string szCache = aryData[j].Replace("\"","").Replace(", ","");
                if(aryData[j].ToLowercase() == "true")
                    Json[aryName[j]] = true;
                else if(aryData[j].ToLowercase() == "false")
                    Json[aryName[j]] = false;
                else if(atof(aryData[j]) != 0)
                    Json[aryName[j]] = atof(aryData[j]);
                else if(aryData[j].ToLowercase() == "0")
                    Json[aryName[j]] = 0;
                else
                    Json[aryName[j]] = aryData[j].Replace("\"","");
            }
        }
        return Json;
    }

    //获取
    void AnaJson(string&in strJson)
    {
        strJson.Replace("\n","");
        if(!BracketsCheack(strJson))
        {
            return;
        }
        array<string>aryJson = SplitMeta(strJson);
        for(uint i =0;i<aryJson.length();i++)
        {
            string objName = aryJson[i].SubString(0,aryJson[i].FindFirstOf(" {")-1);
            objName = objName.Replace(":","").Replace( "\"", ""); 
            JsonData[objName] = dicJson(aryJson[i]); 
        }
    }

    dictionary GetJson
    {
        get { return JsonData; }
        set { JsonData = value; }
    }
}
//实例化
CJson Json; 

void PluginInit()
{
    string test = "{
    \"name\": \"Json\",
    \"url\": \"http://www.balabala.com\",
    \"page\": 88,
    \"isNonProfit\": true,
    \"address\": {
        \"street\": \"888Ave.\",
        \"city\": \"England\",
        \"country\": \"Mars\"
    }}";
    Json.AnaJson(test);
    dictionary MeJson = Json.GetJson;
    g_PlayerFuncs.CenterPrintAll(string(MeJson["name"]) + "," + string(dictionary(MeJson["address"])["street"]));
}
# UnbiasedAIBenchmark
Unbiased AI BenchMarks

### Why
Benchmarks i see around never match with my personal experience using the models. I want to offer real unbiased tests everyone can run and make their own conclusions.

### Models tested

Models tested are only free versions available for everyone to use (which are the ones most people have access to).  
  
- GPT-5.2 Instant 
- Gemini 3.0 Flash / Pro
- DeepSeek 3.2
- Sonnet 4.5
- Kimi K2

### About tests

Tests will be listed below with the results from each model and a score from 0 to 100 based on my analisis of the response. Same prompt used to all models.

####  Test 1. Generate a base64 string. (no thinking)

[Test Details: Prompt + outputs + evaluation of output](https://github.com/StringManolo/UnbiasedAIBenchmark/blob/main/tests/test1.md)

| Model | Overall |
| :--- | :--- | 
| GPT-5.2 Instant | 85 | 
| Gemini 3.0 Flash | 37.5 | 
| DeepSeek 3.2 | 35 | 
| Sonnet 4.5 | 80 | 
| Kimi K2 | 43.75 | 

###### Summary:  
ChatGPT and Sonnet completed the task. 
  
ChatGPT answered directly.  
  
Sonnet had a bit more noise in the output.  
  
Other models missed just by 1 character (after decoding b64).  

#### Test 2. Philosophical question about bad habits and life. (thinking)

[Test Details: Prompt + outputs + evaluation of output](https://github.com/StringManolo/UnbiasedAIBenchmark/blob/main/tests/test2.md)

| Model | Overall |
| :--- | :--- | 
| GPT-5.2 Instant | 35 | 
| Gemini 3.0 Pro | 27.5 | 
| DeepSeek 3.2 | 12.5 | 
| Sonnet 4.5 | 37.75 | 
| Kimi K2 | 62 | 

###### Summary:  
Only Kimi K2 had freedom enought to focusing on answering the philosophical question the user asked while also providing good health habits recommendations.  
  
Other models main focus is to try to force/gaslight the user to quit smoking (which is not bad, but doing so, they miss the question itself, not answering the prompt).  
  
Sonnet keep it usefull and short. 
  
GPT provides good advice with very good references to articles.  
  
Gemini answer is somewhat usefull but dismisses the question and tryies to keep the conversation going instead of condensing into a single output.  
  
DeepSeek took double the time to answer while not providing a more usefull answer, also keeping the philosophical segment abstract.

#### Test 3. Complete the missing bash function from 1047 lines bash code. (no thinking)

[Test Details: Prompt + outputs + evaluation of output](https://github.com/StringManolo/UnbiasedAIBenchmark/blob/main/tests/test3.md)

| Model | Overall |
| :--- | :--- | 
| GPT-5.2 Instant | 77.5 | 
| Gemini 3.0 Flash | 67.75 | 
| DeepSeek 3.2 | 78.75 | 
| Sonnet 4.5 | 92 | 
| Kimi K2 | 80.75 | 

###### Summary: 
Sonnet did an amazing job. Properly usage of colors, all info needed for the user to use the client. Color choice maybe no the pretiest, but good overall.  
  
Kimi did a solid job. UI presentation needs polishing (ugly and to cluttered). But all needed info is there. Kimi took very long to answer. 
  
DeepSeek did include all the info required for a user to use the client without prior knowledge of the software. Did not use colors properly to help the user digest the UI at first glance. In other words, ugly but works perfectly.
  
ChatGPT did a clean client. Simple, well organized and smart use of colors. Pretty design. But mandatory info for the user is missing. 
  
Gemini Flash did had multiple sintax errors that I had to manually fix. The UI has lot of info but misses the arguments needed for the user to know how the to use the client.


<!-- ### General conclusions -->

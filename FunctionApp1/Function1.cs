
using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Azure.WebJobs.Host;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FunctionApp1
{
    public class AzureFunctionInvoker
    {
        private HttpClient HttpClient { get; } = new HttpClient();

        public async Task InvokeAsync(string functionId, object payload)
        {
            await HttpClient.PostAsync(functionId, new StringContent(JsonConvert.SerializeObject(payload), Encoding.UTF8, "application/json"));
        }
    }

    public static class Function1
    {
        [FunctionName("Handle")]
        public static async Task<IActionResult> Handle([HttpTrigger(AuthorizationLevel.Function, "post", Route = null)]HttpRequest req, ILogger log)
        {
            JObject body;
            using (var streamReader = new StreamReader(req.Body))
                body = JObject.Parse(await streamReader.ReadToEndAsync());

            var invoker = new AzureFunctionInvoker();

            await invoker.InvokeAsync(Environment.GetEnvironmentVariable("WorkerFunctionName"),
                                      new
                                      {
                                          operationName = "ProcessJobAssignment",
                                          contextVariables = new Dictionary<string, string>(),
                                          input = new
                                          {
                                              jobAssignmentId = "http://some.server.com/my/job/assignment",
                                              content = body
                                          }
                                      });

            return new OkResult();
        }

        [FunctionName("DoWork")]
        public static async Task<IActionResult> DoWork([HttpTrigger(AuthorizationLevel.Function, "post", Route = null)]
                                           HttpRequest req,
                                           ILogger log)
        {
            JObject body;
            using (var streamReader = new StreamReader(req.Body))
                body = JObject.Parse(await streamReader.ReadToEndAsync());

            Console.WriteLine("Received request to do work:" + Environment.NewLine + body.ToString(Formatting.Indented));

            return new OkResult();
        }
    }
}

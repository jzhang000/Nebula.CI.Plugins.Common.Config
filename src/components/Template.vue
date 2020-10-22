<template>
  <div style="width: 380px">
    <a-collapse v-model="activeKey">
      <a-collapse-panel key="1" header="属性信息">
        <a-table
          :columns="columns"
          :data-source="data"
          :customRow="Rowclick"
          bordered
          size="small"
        >
          <template
            v-for="col in ['param']"
            :slot="col"
            slot-scope="text, record"
          >
            <div :key="col">
              <a-input
                v-if="record.editable"
                style="margin: -5px 0"
                :value="text"
                @change="(e) => handleChange(e.target.value, record.key, col)"
                @blur="saveData"
              />
              <template v-else>
                <span :title="text">{{ text }}</span>
              </template>
            </div>
          </template>
        </a-table>
      </a-collapse-panel>
      <a-collapse-panel key="2" header="输入资源信息">
        <a-table
          :columns="resourceColumns"
          :data-source="inputResourceData"
          bordered
          size="small"
        >
          <template slot="name" slot-scope="text">
            <span>{{ text }}</span>
          </template>
          <template slot="resource" slot-scope="text, record">
            <a-select
              v-model="record.resource"
              style="width: 180px"
              :showArrow="showArrow"
              @blur="saveData"
            >
              <a-select-option
                v-for="item in getInputOptions(record.type)"
                :key="item.name"
                :value="item.name"
                >{{ item.annoName }}</a-select-option
              >
            </a-select>
          </template>
        </a-table>
      </a-collapse-panel>
      <a-collapse-panel key="3" header="输出资源信息">
        <a-table
          :columns="resourceColumns"
          :data-source="outputResourceData"
          bordered
          size="small"
        >
          <template slot="name" slot-scope="text">
            <span>{{ text }}</span>
          </template>
          <template slot="resource" slot-scope="text, record">
            <a-select
              v-model="record.resource"
              style="width: 180px"
              :showArrow="showArrow"
              @blur="saveData"
            >
              <a-select-option
                v-for="item in getOutputOptions(record.type)"
                :key="item.name"
                :value="item.name"
                >{{ item.annoName }}</a-select-option
              >
            </a-select>
          </template>
        </a-table>
      </a-collapse-panel>
    </a-collapse>
    <!-- <a-affix :offset-bottom="top">
      <a-button @click="saveData()" icon="form" id="button" style="background:rgb(68, 119, 136);color:#ffffff;display: block;margin: 0 auto;"> 保存 </a-button>
    </a-affix>-->
  </div>
</template>
<script>
import axios from "axios";

const baseUrl = process.env.API_BASE_URL ? process.env.API_BASE_URL : config.baseUrl;
const pluginPath = process.env.API_PLUGIN_PATH ? process.env.API_PLUGIN_PATH : config.pluginPath
const resourcePath = process.env.API_RESOURCE_PATH ? process.env.API_RESOURCE_PATH : config.resourcePath

const columns = [
  {
    title: "属性名称",
    dataIndex: "description",
    width: "100px",
    scopedSlots: { customRender: "name" },
  },
  {
    title: "参数",
    dataIndex: "param",
    width: "180px",
    scopedSlots: { customRender: "param" },
    ellipsis: true,
  },
];

const resourceColumns = [
  {
    title: "资源名称",
    dataIndex: "description",
    width: "100px",
    scopedSlots: { customRender: "name" },
  },
  {
    title: "资源",
    dataIndex: "resource",
    width: "180px",
    scopedSlots: { customRender: "resource" },
    ellipsis: true,
  },
];

const data = [];
const inputResourceData = [];
const outputResourceData = [];

export default {
  data() {
    this.cacheData = data.map((item) => ({ ...item }));
    return {
      data,
      columns,
      inputResourceData,
      outputResourceData,
      resourceColumns,
      editingKey: "",
      activeKey: ["1", "2", "3"],
      top: 0,
      resourceList: [],
      baseUrl,
      pluginPath,
      resourcePath,
      showArrow: false,
    };
  },
  mounted() {
    this.getResources();

    window.addEventListener("message", (event) => {
      var data = event.data;
      if (data.cmd == "clickNode") {
        var type = data.params.type;
        var property = data.params.property;

        let paramData = [];
        let inputData = [];
        let outputData = [];
        if (property != "") {
          paramData = property.params;
          inputData = property.resources.inputs;
          outputData = property.resources.outputs;
        }
        let that = this;
        axios
          .get(that.baseUrl + this.pluginPath + type)
          .then(function (res) {
            that.data = [];
            for (let i = 0; i < res.data.params.length; i++) {
              let nodePropertyParam = paramData.find(
                (a) => a.name == res.data.params[i].name
              );
              that.data.push({
                key: i.toString(),
                name: res.data.params[i].name,
                description: res.data.params[i].description,
                param: nodePropertyParam ? nodePropertyParam.value : "",
              });
            }

            that.inputResourceData = [];
            for (let i = 0; i < res.data.resources.inputs.length; i++) {
              let nodePropertyInput = inputData.find(
                (a) => a.name == res.data.resources.inputs[i].name
              );
              that.inputResourceData.push({
                key: i.toString(),
                name: res.data.resources.inputs[i].name,
                description: res.data.resources.inputs[i].description,
                resource: nodePropertyInput ? nodePropertyInput.resource : "",
                optional: res.data.resources.inputs[i].optional,
                type: res.data.resources.inputs[i].type,
              });
            }

            that.outputResourceData = [];
            for (let i = 0; i < res.data.resources.outputs.length; i++) {
              let nodePropertyOutput = outputData.find(
                (a) => a.name == res.data.resources.outputs[i].name
              );
              that.outputResourceData.push({
                key: i.toString(),
                name: res.data.resources.outputs[i].name,
                description: res.data.resources.outputs[i].description,
                resource: nodePropertyOutput ? nodePropertyOutput.resource : "",
                optional: res.data.resources.outputs[i].optional,
                type: res.data.resources.outputs[i].type,
              });
            }

            that.cacheData = that.data.map((item) => ({ ...item }));
          })
          .catch(function (error) {
            console.log(error);
          });
      }
    });
  },
  methods: {
    getInputOptions(type) {
      let targetResource = this.resourceList.filter((e) => e.name == type);
      let resources = targetResource[0].resources;
      return resources;
    },
    getOutputOptions(type) {
      let targetResource = this.resourceList.filter((e) => e.name == type);
      let resources = targetResource[0].resources;
      return resources;
    },
    getResources() {
      let that = this;
      axios
        .get(that.baseUrl + this.resourcePath)
        .then(function (res) {
          that.resourceList = res.data;
        })
        .catch(function (error) {
          console.log(error);
        });
    },
    handleChange(value, key, column) {
      const newData = [...this.data];
      const target = newData.filter((item) => key === item.key)[0];
      if (target) {
        target[column] = value;
        this.data = newData;
      }
    },
    Rowclick(record, index) {
      return {
        on: {
          click: () => {}, //表格行 点击事件
          dblclick: () => {}, //表格行 双击事件
          mouseenter: (event) => {
            const newData = [...this.data];
            const target = newData.filter((item) => record.key === item.key)[0];
            this.editingKey = record.key;
            if (target) {
              target.editable = true;
              this.data = newData;
            }
          },
          mouseleave: (event) => {
            const newData = [...this.data];
            const newCacheData = [...this.cacheData];
            const target = newData.filter((item) => record.key === item.key)[0];
            const targetCache = newCacheData.filter(
              (item) => record.key === item.key
            )[0];
            if (target && targetCache) {
              delete target.editable;
              this.data = newData;
              Object.assign(targetCache, target);
              this.cacheData = newCacheData;
            }
            this.editingKey = "";
          },
        },
      };
    },
    saveData() {
      let data = {};
      let paramsData = [];
      let resources = {};
      let inputsData = [];
      let outputsData = [];

      this.data.forEach((e) => {
        paramsData.push({ name: e.name, value: e.param });
      });

      this.inputResourceData.forEach((e) => {
        inputsData.push({ name: e.name, resource: e.resource });
      });

      this.outputResourceData.forEach((e) => {
        outputsData.push({ name: e.name, resource: e.resource });
      });

      resources["inputs"] = inputsData;
      resources["outputs"] = outputsData;

      data["resources"] = resources;
      data["params"] = paramsData;

      window.parent.postMessage(
        {
          cmd: "property",
          params: {
            data: data,
          },
        },
        "*"
      );
    },
  },
};
</script>
<style scoped>
.editable-row-operations a {
  margin-right: 8px;
}

.ant-table-body {
  overflow-x: auto !important;
}

.ant-table-thead {
  background: cadetblue;
}
</style>

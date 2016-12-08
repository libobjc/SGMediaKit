# SGMediaKit & SGPlayer VR全景播放器 

### SGMediaKit 是一个以视频、音频播放为核心的媒体资源处理框架。
项目还在持续开发中，组件介绍及开发进度如下:
- SGPlayer — 音视频播放器。 支持普通视频和VR全景视频，可随意切换单双眼模式。
- SGCpature - 媒体捕获。 支持摄像头、麦克风数据捕获，可将捕获数据输出视频文件。
- SGFormat - 视频转码。 目前仅支持 H.264/AAC，持续更新。
- SGLive - 直播推流。 待开发。

===
### 关于编译
![build_choose](https://github.com/0x010101/SGMediaKit/blob/master/GitHub/build_%20choose.png)
- 项目包含两个Target。
- 可编译完整SGMediaKit（包含SGPlayer），也可仅编译SGPlayer。
- 编译SGMediaKit需要依赖[GPUImage](https://github.com/BradLarson/GPUImage)

# PhysicalFlow

This repository is a lightweight fork of the open-source GoalFlow codebase, kept for further research and experimentation. Non-essential paper PDFs and showcase media have been removed from this fork to keep the working tree smaller.

The original authorship, license, citation, acknowledgements, and external project links are preserved below.

Original project links: [Paper](https://arxiv.org/abs/2503.05689) | [Weights](https://drive.google.com/drive/folders/1iWsPwpqM4WaUVVRZU3xIMPdOaJVB2Kub?usp=drive_link) | [Project Page](https://zebinx.github.io/HomePage-of-GoalFlow/)

> [**GoalFlow: Goal-Driven Flow Matching for Multimodal Trajectories Generation
in End-to-End Autonomous Driving**](https://arxiv.org/abs/2503.05689)  <br>
> [Zebin Xing](https://github.com/ZebinX)<sup>1,2*</sup>, [Xingyu Zhang]()<sup>2*</sup>, [Yang Hu]()<sup>1,2</sup>, [Bo Jiang]()<sup>4,2</sup>, [Tong He](https://tonghe90.github.io/)<sup>5</sup>, [Qian Zhang]()<sup>2</sup>, [Xiaoxiao Long](https://www.xxlong.site/)<sup>3</sup>, [Wei Yin](https://yvanyin.xyz/)<sup>2</sup>  <br>
> <sup>1</sup> University of Chinese Academy of Sciences, <sup>2</sup> Horizon Robotics, <sup>3</sup> Nanjing University, <sup>4</sup> Huazhong University of Science & Technology, Shanghai AI Laboratory  <br>
> Computer Vision and Pattern Recognition (CVPR), 2025

This is a fork of the official repo of "GoalFlow: Goal-Driven Flow Matching for Multimodal Trajectories Generation in End-to-End Autonomous Driving (CVPR 2025)". GoalFlow achieved PDMS of 90.3, significantly surpassing other baselines. Compared with other diffusion-policy-based methods, the approach requires only a single denoising step to obtain strong performance.

## Notes for This Fork

- The local `GoalFlow.pdf` paper copy has been removed. Use the arXiv link above for the paper.
- README showcase images, GIFs, and goal-point visualization assets have been removed.
- No tracked checkpoint or model-weight binary was found in this repository at cleanup time.
- Checkpoints and pretrained weights are still referenced in the original docs and scripts, and should be downloaded to the configured data directory when needed.

## News

* **`20 Mar, 2025`:** GoalFlow paper released on [arXiv](https://arxiv.org/abs/2503.05689).
* **`27 Feb, 2025`:** GoalFlow was accepted at [CVPR](https://cvpr.thecvf.com/Conferences/2025).

## Introduction

> In autonomous driving, multiple optimal trajectories exist, like overtaking or following. (1) Traditional methods efficiently generate safe trajectories but struggle with multimodal ones. (2) Generative methods like diffusion models capture multimodal distributions but require heavy hardware and prior information. GoalFlow is a goal-point-based method that guides trajectory planning. With a map-free evaluation and an efficient diffusion variant, Flow Matching, it reduces inference steps, achieving strong performance with just one denoising step.

## Results

Planning results on the proposed **NAVSIM** **Test** benchmark. Please refer to the [paper](https://arxiv.org/abs/2503.05689) for more details.

| Method | S<sub>NC</sub> | S<sub>DAC</sub> | S<sub>TTC</sub> | S<sub>CF</sub> | S<sub>EP</sub> | S<sub>PDM</sub> |
| --- | --- | --- | --- | --- | --- | --- |
| Constant Velocity | 68.0 | 57.8 | 50.0 | 100 | 19.4 | 20.6 |
| Ego Status MLP | 93.0 | 77.3 | 83.6 | 100 | 62.8 | 65.6 |
| LTF | 97.4 | 92.8 | 92.4 | 100 | 79.0 | 83.8 |
| TransFuser | 97.7 | 92.8 | 92.8 | 100 | 79.2 | 84.0 |
| UniAD | 97.8 | 91.9 | 92.9 | 100 | 78.8 | 83.4 |
| PARA-Drive | 97.9 | 92.4 | 93.0 | 99.8 | 79.3 | 84.0 |
| **GoalFlow** | **98.4** | **98.3** | **94.6** | **100** | **85.0** | **90.3** |
| *Human* | *100* | *100* | *100* | *99.9* | *87.5* | *94.8* |

## Getting Started

- [Download Datasets of NAVSIM](https://github.com/autonomousvision/navsim/blob/main/docs/install.md)
- [Preparation of GoalFlow Environment](docs/install.md)
- [Evaluation](docs/test.md)
- [Training](docs/train.md)

The original scripts reference externally downloaded checkpoints and weights, for example:

- `goalflow_traj_epoch_54-step_18260.ckpt`
- `goalflow_navi_epoch_99-step_132500.ckpt`
- `depth_pretrained_v99-3jlw0p36-20210423_010520-model_final-remapped.pth`

## Contact

For questions about the original GoalFlow project, please open an issue in the upstream project or contact the original authors at xzebin@bupt.edu.cn.

## Acknowledgement

1. The original project gained valuable insights from [Hydra-MDP](https://arxiv.org/abs/2406.06978).
2. The original project referred to [tuplan garage](https://github.com/autonomousvision/tuplan_garage) and incorporated aspects of its page design.
3. GoalFlow is also inspired by open-source projects including [NAVSIM](https://github.com/autonomousvision/navsim), [TransFuser](https://github.com/autonomousvision/transfuser), [Diffusion-ES](https://github.com/hustvl/VAD), and VAD-v2.

## Citation

If you find GoalFlow useful, please consider citing the paper with the following BibTeX entry.

```BibTeX
@article{xing2025goalflow,
  title={GoalFlow: Goal-Driven Flow Matching for Multimodal Trajectories Generation in End-to-End Autonomous Driving},
  author={Xing, Zebin and Zhang, Xingyu and Hu, Yang and Jiang, Bo and He, Tong and Zhang, Qian and Long, Xiaoxiao and Yin, Wei},
  journal={arXiv preprint arXiv:2503.05689},
  year={2025}
}
```

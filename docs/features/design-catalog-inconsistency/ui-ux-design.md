# Design Catalog Inconsistency UX Design Guide

## Overview
이 문서는 디자인 카탈로그에서 발견된 타이포그래피 계층 구조 역전 문제와 테두리 반경(Radius) 수치 불일치 문제를 해결하기 위한 디자인 시스템 표준 가이드를 제공합니다.

## Typography Standard (#1717)

### Problem
현재 `displayLarge`가 32.0으로 정의되어 있어, Material 3 기본값인 `displayMedium` (45.0) 및 `displaySmall` (36.0)보다 작게 표시되는 계층 구조 역전 현상이 발생하고 있습니다.

### Solution
브랜드 아이덴티티와 사용성을 고려하여 Display 시리즈의 폰트 크기를 다음과 같이 재정의합니다.

| Token | Size (px) | Weight | Line Height |
|-------|-----------|--------|-------------|
| **displayLarge** | 48.0 | Bold | 1.2 |
| **displayMedium** | 40.0 | Bold | 1.2 |
| **displaySmall** | 32.0 | Bold | 1.25 |

- 기존 `displayLarge`로 사용되던 32.0은 `displaySmall`로 강등(?)시키고, 상위에 더 큰 타이틀을 위한 토큰을 확보합니다.

## Radius Standard (#1718)

### Problem
디자인 카탈로그(`RadiusSection`)의 라벨 텍스트와 실제 `MinglitRadius` 토큰 값이 일치하지 않습니다. (라벨: 16/24, 실제: 12/16)

### Solution
라벨의 하드코딩된 수치를 제거하고, 실제 토큰 값을 동적으로 표시하거나 현재의 표준 수치에 맞춰 라벨을 수정합니다. 밍글릿의 현재 Radius 표준은 다음과 같습니다.

- **button / input**: 12.0
- **card**: 16.0

## Feedback to SWE
- `MinglitTheme`의 `textTheme` 정의에 위 표의 Display 시리즈를 명시적으로 추가해 주세요.
- `RadiusSection.dart`의 `radii` 맵에서 라벨의 괄호 안 숫자를 실제 토큰 값과 일치하도록 수정해 주세요.

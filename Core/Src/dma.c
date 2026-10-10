/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file    dma.c
  * @brief   DMA controller configuration.
  ******************************************************************************
  */
/* USER CODE END Header */
#include "dma.h"

void MX_DMA_Init(void)
{
  __HAL_RCC_DMA2_CLK_ENABLE();

  /* USART1_TX uses DMA2 Stream7. */
  HAL_NVIC_SetPriority(DMA2_Stream7_IRQn, 5, 0);
  HAL_NVIC_EnableIRQ(DMA2_Stream7_IRQn);
}
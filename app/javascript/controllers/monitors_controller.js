import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Connects to data-controller="monitors"
export default class extends Controller {
  static targets = ["status", "uptime", "lastChecked"]
  
  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create("MonitorsChannel", {
      connected() {
        console.log("Connected to MonitorsChannel")
      },
      
      disconnected() {
        console.log("Disconnected from MonitorsChannel")
      },
      
      received: (data) => {
        this.updateMonitor(data)
      }
    })
  }
  
  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }
  
  updateMonitor(data) {
    const monitorElement = document.querySelector(`[data-monitor-id="${data.monitor_id}"]`)
    if (!monitorElement) return
    
    // Update status indicator
    const statusIndicator = monitorElement.querySelector('.status-indicator')
    if (statusIndicator) {
      statusIndicator.className = `status-indicator w-3 h-3 rounded-full ${this.getStatusClass(data.status)}`
    }
    
    // Update uptime percentage
    const uptimeElement = monitorElement.querySelector('.uptime-percentage')
    if (uptimeElement && data.uptime_percentage) {
      uptimeElement.textContent = `${data.uptime_percentage}% uptime`
    }
    
    // Update last checked time
    const lastCheckedElement = monitorElement.querySelector('.last-checked')
    if (lastCheckedElement) {
      lastCheckedElement.textContent = 'Last checked just now'
    }
    
    // Update response time if available
    const responseTimeElement = monitorElement.querySelector('.response-time')
    if (responseTimeElement && data.response_time) {
      responseTimeElement.textContent = `${Math.round(data.response_time)}ms`
    }
    
    // Show notification for status changes
    if (data.status === 'down') {
      this.showNotification(`Monitor is DOWN: ${monitorElement.querySelector('.monitor-name').textContent}`, 'error')
    } else if (data.status === 'up') {
      this.showNotification(`Monitor is back UP: ${monitorElement.querySelector('.monitor-name').textContent}`, 'success')
    }
  }
  
  getStatusClass(status) {
    switch(status) {
      case 'up':
        return 'bg-green-400'
      case 'down':
        return 'bg-red-400'
      default:
        return 'bg-gray-400'
    }
  }
  
  showNotification(message, type) {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 p-4 rounded-md z-50 ${
      type === 'error' ? 'bg-red-900 border border-red-700 text-red-200' : 
      'bg-green-900 border border-green-700 text-green-200'
    }`
    notification.textContent = message
    
    // Add to page
    document.body.appendChild(notification)
    
    // Remove after 5 seconds
    setTimeout(() => {
      if (notification.parentNode) {
        notification.parentNode.removeChild(notification)
      }
    }, 5000)
  }
}
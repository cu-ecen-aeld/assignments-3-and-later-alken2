/**
 * @file aesdchar.c
 * @brief Functions and data related to the AESD char driver implementation
 *
 * Based on the implementation of the "scull" device driver, found in
 * Linux Device Drivers example code.
 *
 * @author Dan Walkes
 * @date 2019-10-22
 * @copyright Copyright (c) 2019
 *
 */

#include <linux/module.h>
#include <linux/init.h>
#include <linux/printk.h>
#include <linux/types.h>
#include <linux/cdev.h>
#include <linux/fs.h> // file_operations
#include "aesd-circular-buffer.h"
#include "aesdchar.h"
#include <linux/string.h> 
#include <linux/mutex.h>
#include <linux/slab.h> 
#include <linux/uaccess.h>
int aesd_major =   0; // use dynamic major
int aesd_minor =   0;

MODULE_AUTHOR("Kenneth Alcineus"); /** DONE: fill in your name **/
MODULE_LICENSE("Dual BSD/GPL");

struct aesd_dev aesd_device;

int aesd_open(struct inode *inode, struct file *filp)
{
    PDEBUG("open");
    /**
     * DONE: handle open
     */

    struct aesd_dev *dev_ptr = container_of(inode->i_cdev, aesd_device, cdev);
    filp->private_data = dev_ptr;
    return 0;
}

int aesd_release(struct inode *inode, struct file *filp)
{
    PDEBUG("release");
    /**
     * DONE: handle release
     */

    inode = NULL;
    filp = NULL;
    return 0;
}

ssize_t aesd_read(struct file *filp, char __user *buf, size_t count,
                loff_t *f_pos)
{
    ssize_t retval = 0;
    PDEBUG("read %zu bytes with offset %lld",count,*f_pos);
    /**
     * DONE: handle read
     */
     
    struct aesd_dev *dev_ptr = filp->private_data;
    struct aesd_buffer_entry *entry_ptr = NULL;
    size_t entry_offset = 0;
    size_t bytes_num = 0;

    mutex_lock(&dev_ptr->mtx);

    entry_ptr = aesd_circular_buffer_find_entry_offset_for_fpos(
        &dev->buffer, *f_pos, &entry_offset);

    if (entry_ptr == NULL)
    {
        mutex_unlock(&dev_ptr->mtx);
        return retval;
    }

    bytes_num = entry_ptr->size - entry_offset;

    if (bytes_num > count)
    {
        bytes_num == count;
    }

    if (copy_to_user(buf, entry_ptr->buffptr + entry_offset, bytes_num))
    {
        mutex_unlock(&dev_ptr->mtx);
        retval = -EFAULT;
        return retval;
    }

    mutex_unlock(&dev_ptr->mtx);
    *fpos += bytes_num;
    retval = (ssize_t)bytes_num;
    return retval;
}

ssize_t aesd_write(struct file *filp, const char __user *buf, size_t count,
                loff_t *f_pos)
{
    ssize_t retval = -ENOMEM;
    PDEBUG("write %zu bytes with offset %lld",count,*f_pos);
    /**
     * DONE: handle write
     */

    struct aesd_dev *dev_ptr = filp->private_data;
    char *temp_buffer = NULL;
    size_t entry_offset = 0;
    size_t bytes_num = 0;

    mutex_lock(&dev_ptr->mtx);

    temp_buffer = krealloc(dev_ptr->write_buffer, 
        dev_ptr->write_buffer_size + count, GFP_KERNEL);

    if (temp_buffer == NULL)
    {
        mutex_unlock(&dev_ptr->mtx);
        return retval;
    }

    dev_ptr->write_buffer = temp_buffer;

    if (copy_from_user(dev_ptr->write_buffer + dev->write_buffer_size, buf, count))
    {
        mutex_unlock(&dev_ptr->mtx);
        retval = -EFAULT
        return retval;
    }

    dev_ptr->write_buffer_size += count;

    if (memchr(dev_ptr->write_buffer, '\n', dev_ptr->write_buffer_size))
    {
        struct aesd_buffer_entry entry;

        entry.buffptr = dev_ptr->write_buffer;
        entry.size = dev_ptr->write_buffer_size;

        aesd_circular_buffer_add_entry(&dev_ptr->circular_buffer, &entry);

        dev_ptr->write_buffer = NULL;
        dev_ptr->write_buffer_size = 0;
    }

    mutex_unlock(&dev_ptr->mtx);
    retval = (ssize_t)count;

    return retval;
}
struct file_operations aesd_fops = {
    .owner =    THIS_MODULE,
    .read =     aesd_read,
    .write =    aesd_write,
    .open =     aesd_open,
    .release =  aesd_release,
};

static int aesd_setup_cdev(struct aesd_dev *dev)
{
    int err, devno = MKDEV(aesd_major, aesd_minor);

    cdev_init(&dev->cdev, &aesd_fops);
    dev->cdev.owner = THIS_MODULE;
    dev->cdev.ops = &aesd_fops;
    err = cdev_add (&dev->cdev, devno, 1);
    if (err) {
        printk(KERN_ERR "Error %d adding aesd cdev", err);
    }
    return err;
}



int aesd_init_module(void)
{
    dev_t dev = 0;
    int result;
    result = alloc_chrdev_region(&dev, aesd_minor, 1,
            "aesdchar");
    aesd_major = MAJOR(dev);
    if (result < 0) {
        printk(KERN_WARNING "Can't get major %d\n", aesd_major);
        return result;
    }
    memset(&aesd_device,0,sizeof(struct aesd_dev));

    /**
     * DONE: initialize the AESD specific portion of the device
     */

    mutex_init(&aesd_device.mtx);
    aesd_circular_buffer_init(&aesd_device.circular_buffer);

    result = aesd_setup_cdev(&aesd_device);

    if( result ) {
        unregister_chrdev_region(dev, 1);
    }
    return result;

}

void aesd_cleanup_module(void)
{
    dev_t devno = MKDEV(aesd_major, aesd_minor);

    cdev_del(&aesd_device.cdev);
    struct aesd_buffer_entry *entry_ptr;
    uint8_t index;

    /**
     * DONE: cleanup AESD specific poritions here as necessary
     */

    AESD_CIRCULAR_BUFFER_FOREACH(entry_ptr, &aesd_device.circular_buffer, index)
    {
        if (entry_ptr->buffptr != NULL)
        {
            kfree(entry_ptr->buffptr);
            entry_ptr = NULL;
        }
    }

    if (aesd_device.write_buffer != NULL)
    {
        kfree(aesd_device.write_buffer);
        aesd_device.write_buffer = NULL;
    }

    mutex_destroy(&aesd_device.mtx);

    unregister_chrdev_region(devno, 1);
}



module_init(aesd_init_module);
module_exit(aesd_cleanup_module);
